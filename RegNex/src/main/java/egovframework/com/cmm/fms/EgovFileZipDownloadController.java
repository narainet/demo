package egovframework.com.cmm.fms;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Base64;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.lang.StringUtils;
import org.egovframe.rte.fdl.cryptography.EgovEnvCryptoService;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

import egovframework.com.cmm.EgovBrowserUtil;
import egovframework.com.cmm.service.EgovFileMngService;
import egovframework.com.cmm.service.FileVO;
import egovframework.com.cmm.util.EgovBasicLogger;
import egovframework.com.cmm.util.EgovUserDetailsHelper;

/**
 * 표준 첨부(COMTNFILE/COMTNFILEDETAIL) 다중 ZIP 일괄 다운로드 컨트롤러.
 *
 * FileDown.do(단건)의 일괄 확장 — 특정 모듈 전용이 아닌 공용 컴포넌트로,
 * atchFileId 를 여러 개 받아 각 첨부의 전체 파일을 하나의 ZIP 스트림으로 내려준다.
 * (첫 수요는 송무 소송문서조회의 [ZIP 일괄]이지만 게시판 등 표준 첨부를 쓰는 모든 화면에서 재사용 가능)
 *
 * 보안 규약은 FileDown.do 와 동일:
 *  - 인증 사용자만.
 *  - atchFileId 는 화면 렌더 시점에 "세션ID|파일ID" 를 암호화한 값 — 여기서 복호화해
 *    현재 세션과 일치하는 키만 허용(유추 불가·타세션 무효). 하나라도 불일치면 전체 거부.
 *
 * 파라미터:
 *  - atchFileId (반복) : 암호화된 첨부파일 ID 목록
 *  - zipName (선택)    : 내려줄 ZIP 파일명(확장자 제외). 미지정 시 "attachments"
 */
@Controller
public class EgovFileZipDownloadController {

	/** 암호화서비스 (FileDown.do 와 동일 빈 — atchFileId 세션 키 복호화) */
	@Resource(name = "egovEnvCryptoService")
	EgovEnvCryptoService cryptoService;

	@Resource(name = "EgovFileMngService")
	private EgovFileMngService fileService;

	@RequestMapping(value = "/cmm/fms/FileZipDown.do")
	public void fileZipDownload(HttpServletRequest request, HttpServletResponse response) throws Exception {

		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}

		String[] encodedIds = request.getParameterValues("atchFileId");
		if (encodedIds == null || encodedIds.length == 0) {
			response.sendError(HttpServletResponse.SC_BAD_REQUEST);
			return;
		}

		// 복호화 + 세션 일치 검증 — 위조·타세션 키가 하나라도 섞이면 전체 거부
		String sessionId = request.getSession().getId();
		Set<String> atchFileIds = new LinkedHashSet<String>();
		for (String encoded : encodedIds) {
			String cleaned = encoded.replaceAll(" ", "+");
			String decodedString = cryptoService.decrypt(new String(Base64.getDecoder().decode(cleaned)));
			String decodedSessionId = StringUtils.substringBefore(decodedString, "|");
			String decodedFileId = StringUtils.substringAfter(decodedString, "|");
			if (!StringUtils.equals(decodedSessionId, sessionId) || StringUtils.isEmpty(decodedFileId)) {
				throw new Exception("FileZipDown: invalid file key");
			}
			atchFileIds.add(decodedFileId);
		}

		// 첨부별 파일 상세 수집 (COMTNFILEDETAIL 사용여부 'Y' 행들)
		List<FileVO> targets = new ArrayList<FileVO>();
		for (String atchFileId : atchFileIds) {
			FileVO param = new FileVO();
			param.setAtchFileId(atchFileId);
			List<FileVO> files = fileService.selectFileInfs(param);
			if (files != null) {
				targets.addAll(files);
			}
		}

		String zipName = request.getParameter("zipName");
		if (zipName == null || zipName.trim().isEmpty()) {
			zipName = "attachments";
		}
		// 파일시스템 예약문자 제거 (다운로드 파일명으로만 쓰임)
		zipName = zipName.trim().replaceAll("[\\\\/:*?\"<>|]", "_") + ".zip";

		String userAgent = request.getHeader("User-Agent");
		response.setContentType("application/zip");
		response.setHeader("Content-Disposition", EgovBrowserUtil.getDisposition(zipName, userAgent, "UTF-8"));

		// ZIP 엔트리명은 UTF-8(기본) — 언어 인코딩 플래그가 설정되어 현행 압축 도구에서 한글 파일명 정상
		Set<String> usedNames = new HashSet<String>();
		ZipOutputStream zos = null;
		BufferedInputStream in = null;
		try {
			zos = new ZipOutputStream(response.getOutputStream());
			for (FileVO fvo : targets) {
				File uFile = new File(fvo.getFileStreCours(), fvo.getStreFileNm());
				if (!uFile.isFile() || uFile.length() <= 0) {
					continue;
				}

				zos.putNextEntry(new ZipEntry(uniqueEntryName(usedNames, fvo.getOrignlFileNm())));
				try {
					in = new BufferedInputStream(new FileInputStream(uFile));
					byte[] buffer = new byte[8192];
					int len;
					while ((len = in.read(buffer)) != -1) {
						zos.write(buffer, 0, len);
					}
				} finally {
					if (in != null) {
						try { in.close(); } catch (IOException ignore) { EgovBasicLogger.ignore("close", ignore); }
						in = null;
					}
				}
				zos.closeEntry();

				// 파일별 다운로드 수 +1 (자료실형 통계 동승) — 실패해도 다운로드는 계속
				try {
					fileService.increaseFileDownloadCount(fvo);
				} catch (Exception ignore) {
					EgovBasicLogger.ignore("다운로드 수 갱신 실패", ignore);
				}
			}
			zos.finish();
			zos.flush();
		} catch (IOException ex) {
			// Connection reset by peer 류 — 클라이언트 중단은 무시
			EgovBasicLogger.ignore("IO Exception", ex);
		} finally {
			if (zos != null) {
				try { zos.close(); } catch (IOException ignore) { EgovBasicLogger.ignore("close", ignore); }
			}
		}
	}

	/** ZIP 내 엔트리명 중복 시 " (1)", " (2)" 접미. 원본명이 비면 "file" 대체. */
	private String uniqueEntryName(Set<String> used, String orignlFileNm) {
		String base = (orignlFileNm == null || orignlFileNm.trim().isEmpty()) ? "file" : orignlFileNm.trim();
		if (used.add(base)) {
			return base;
		}
		String name = base;
		String ext = "";
		int dot = base.lastIndexOf('.');
		if (dot > 0) {
			name = base.substring(0, dot);
			ext = base.substring(dot);
		}
		for (int i = 1; ; i++) {
			String candidate = name + " (" + i + ")" + ext;
			if (used.add(candidate)) {
				return candidate;
			}
		}
	}
}
