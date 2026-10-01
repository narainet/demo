/*
 * 물리적 저장 경로: /src/main/java/narainet/law/common/service/LawFileSupport.java
 *
 * 표준 COMTNFILE/COMTNFILEDETAIL 첨부 처리 공용 헬퍼 (§6 — 표준 베이스 원칙).
 *   선임 계약서·소송문서 첨부가 동일하게 사용 — EgovFileMngUtil.parseFileInf + EgovFileMngService.insertFileInfs.
 *   ※ 도메인 첨부정책(TB_ATTACH)의 의도적 예외 — 송무 단독배포 성립 위해 표준 흡수(§1.3-3).
 */
package narainet.law.common.service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import javax.annotation.Resource;

import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import egovframework.com.cmm.service.EgovFileMngService;
import egovframework.com.cmm.service.EgovFileMngUtil;
import egovframework.com.cmm.service.FileVO;

@Component("lawFileSupport")
public class LawFileSupport {

	/** 송무 첨부 저장 루트 프로퍼티 키 — globals.properties 의 Globals.fileStorePath.Law (예: D:/upload/law/) */
	private static final String STORE_PATH_KEY = "Globals.fileStorePath.Law";

	@Resource(name = "EgovFileMngUtil")
	private EgovFileMngUtil fileUtil;

	@Resource(name = "EgovFileMngService")
	private EgovFileMngService fileMngService;

	/**
	 * 첨부 저장 — 신규면 ATCH_FILE_ID 채번, 기존이면 이어붙임(fileSn 증분).
	 * 실 업로드 파일이 없으면 기존 atchFileId 를 그대로 반환(변경 없음).
	 *
	 * <p>저장 위치는 <code>D:/upload/law/&lt;subDir&gt;/</code> — 기능별로 폴더가 갈린다.</p>
	 *
	 * @param atchFileId 기존 첨부 ID (신규 등록이면 null/빈값)
	 * @param files      업로드 파트 목록(빈 파트 허용 — 내부에서 제거)
	 * @param keyPrefix  파일 그룹 키 접두(예: "LAW_")
	 * @param subDir     기능별 하위 폴더명(req/doc/assign/seize/receipt)
	 * @return 저장 후 유효한 ATCH_FILE_ID (없으면 기존값)
	 */
	public String saveFiles(String atchFileId, List<MultipartFile> files, String keyPrefix, String subDir) throws Exception {
		String existing = (atchFileId == null || atchFileId.trim().isEmpty()) ? null : atchFileId.trim();
		if (files == null || files.isEmpty()) {
			return existing;
		}
		List<MultipartFile> real = new ArrayList<MultipartFile>();
		for (MultipartFile f : files) {
			if (f != null && !f.isEmpty()) {
				real.add(f);
			}
		}
		if (real.isEmpty()) {
			return existing;
		}
		if (existing == null) {
			List<FileVO> parsed = fileUtil.parseFileInf(real, keyPrefix, 0, "", STORE_PATH_KEY, subDir);
			return fileMngService.insertFileInfs(parsed);
		}
		FileVO param = new FileVO();
		param.setAtchFileId(existing);
		int cnt = fileMngService.getMaxFileSN(param);
		List<FileVO> parsed = fileUtil.parseFileInf(real, keyPrefix, cnt, existing, STORE_PATH_KEY, subDir);
		fileMngService.updateFileInfs(parsed);
		return existing;
	}

	/**
	 * 첨부 개수·용량 검증 (§7.10 압류=5개·10MB 등) — 위반 시 사유 메시지, 정상이면 null.
	 * 기존 첨부(atchFileId) 개수 + 신규 업로드 개수를 합산해 maxCount 를 넘는지, 개당 maxBytes 를 넘는지 확인.
	 *
	 * @param atchFileId 기존 첨부 ID (신규 등록이면 null/빈값)
	 * @param files      업로드 파트 목록(빈 파트 허용 — 내부에서 무시)
	 * @param maxCount   최대 첨부 개수(기존+신규 합산)
	 * @param maxBytes   개당 최대 바이트
	 */
	public String validateFiles(String atchFileId, List<MultipartFile> files, int maxCount, long maxBytes) throws Exception {
		int existing = list(atchFileId).size();
		int add = 0;
		if (files != null) {
			for (MultipartFile f : files) {
				if (f != null && !f.isEmpty()) {
					add++;
					if (f.getSize() > maxBytes) {
						return "첨부파일은 개당 " + (maxBytes / 1024 / 1024) + "MB 이하만 등록할 수 있습니다.";
					}
				}
			}
		}
		if (existing + add > maxCount) {
			return "첨부파일은 최대 " + maxCount + "개까지 등록할 수 있습니다. (현재 " + existing + "개)";
		}
		return null;
	}

	/** 첨부 파일 상세 목록(COMTNFILEDETAIL 사용여부 'Y') — 없으면 빈 목록. */
	public List<FileVO> list(String atchFileId) throws Exception {
		if (atchFileId == null || atchFileId.trim().isEmpty()) {
			return Collections.emptyList();
		}
		FileVO param = new FileVO();
		param.setAtchFileId(atchFileId.trim());
		List<FileVO> files = fileMngService.selectFileInfs(param);
		return files == null ? Collections.<FileVO>emptyList() : files;
	}
}
