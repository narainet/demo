/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/uss/ion/brd/web/EgovBrandController.java
 *
 * 브랜드설정(로고·파비콘) 컨트롤러.
 *
 *  · 설정 화면/저장 : /uss/ion/brd/*   — 관리자 전용
 *  · 이미지 서빙    : /cmm/brand/*     — 로그인 화면에도 로고가 나와야 하므로 인증 없이 열어 둔다
 *                                        (읽기 전용 + 브랜드 이미지라 노출되어도 무방)
 */
package egovframework.com.uss.ion.brd.web;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.multipart.MultipartHttpServletRequest;

import egovframework.com.cmm.EgovMessageSource;
import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.service.EgovFileMngService;
import egovframework.com.cmm.service.EgovFileMngUtil;
import egovframework.com.cmm.service.FileVO;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import egovframework.com.uss.ion.brd.service.Brand;
import egovframework.com.uss.ion.brd.service.BrandInfo;
import egovframework.com.uss.ion.brd.service.EgovBrandService;
import egovframework.com.utl.fcc.service.EgovStringUtil;

@Controller
public class EgovBrandController {

	private static final Logger LOGGER = LoggerFactory.getLogger(EgovBrandController.class);

	/** 업로드 허용 확장자 — 이미지만. 서버에서 다시 검사한다(화면 accept 속성은 우회 가능). */
	private static final String ALLOW_LOGO = ".png.jpg.jpeg.gif.svg.";

	/** 파비콘은 브라우저가 읽는 형식만 */
	private static final String ALLOW_FAVICON = ".png.svg.ico.gif.jpg.jpeg.";

	/** 저장 폴더 프로퍼티 키 — globals.properties 의 Globals.fileStorePath.Brand (예: D:/upload/brand/) */
	private static final String STORE_PATH_KEY = "Globals.fileStorePath.Brand";

	@Resource(name = "egovBrandService")
	private EgovBrandService egovBrandService;

	@Resource(name = "EgovFileMngService")
	private EgovFileMngService fileMngService;

	@Resource(name = "EgovFileMngUtil")
	private EgovFileMngUtil fileUtil;

	@Resource(name = "egovMessageSource")
	private EgovMessageSource egovMessageSource;

	/**
	 * 브랜드설정 화면.
	 */
	@RequestMapping(value = "/uss/ion/brd/brandView.do")
	public String brandView(ModelMap model) throws Exception {
		model.addAttribute("brand", egovBrandService.selectBrand());
		model.addAttribute("brandVersion", BrandInfo.getVersion());   // 미리보기 캐시버스터
		return "egovframework/com/uss/ion/brd/EgovBrand";
	}

	/**
	 * 브랜드설정을 저장한다. 로고/파비콘은 올린 것이 있을 때만 교체한다.
	 */
	@RequestMapping(value = "/uss/ion/brd/updtBrand.do")
	public String updateBrand(final MultipartHttpServletRequest multiRequest,
			@ModelAttribute("brand") Brand brand, ModelMap model) throws Exception {

		Map<String, MultipartFile> files = multiRequest.getFileMap();

		String logoId = storeIfPresent(files, "logoFile", ALLOW_LOGO);
		if (logoId != null) {
			brand.setLogoAtchFileId(logoId);
		} else {
			brand.setLogoAtchFileId("");     // 매퍼가 빈 값이면 기존 첨부를 유지한다
		}

		String faviconId = storeIfPresent(files, "faviconFile", ALLOW_FAVICON);
		if (faviconId != null) {
			brand.setFaviconAtchFileId(faviconId);
		} else {
			brand.setFaviconAtchFileId("");
		}

		// 이미지 모드인데 올린 로고도 없고 기존 로고도 없으면 텍스트로 되돌린다 — 빈 헤더 방지
		if (Brand.TY_IMAGE.equals(brand.getLogoTyCode())
				&& (brand.getLogoAtchFileId() == null || brand.getLogoAtchFileId().isEmpty())
				&& !BrandInfo.get().isImageLogo()) {
			brand.setLogoTyCode(Brand.TY_TEXT);
		}

		LoginVO user = (LoginVO) EgovUserDetailsHelper.getAuthenticatedUser();
		brand.setLastUpdusrId(user == null ? "" : EgovStringUtil.isNullToString(user.getId()));

		egovBrandService.updateBrand(brand);
		model.addAttribute("message", egovMessageSource.getMessage("success.common.update"));
		return "forward:/uss/ion/brd/brandView.do";
	}

	/** 올린 파일이 있으면 저장하고 첨부ID 를 돌려준다. 없으면 null. */
	private String storeIfPresent(Map<String, MultipartFile> files, String field, String allowed) throws Exception {
		MultipartFile mf = (files == null) ? null : files.get(field);
		if (mf == null || mf.isEmpty()) {
			return null;
		}
		String name = mf.getOriginalFilename() == null ? "" : mf.getOriginalFilename();
		int dot = name.lastIndexOf('.');
		String ext = (dot < 0) ? "" : name.substring(dot + 1).toLowerCase();
		if (ext.isEmpty() || allowed.indexOf("." + ext + ".") < 0) {
			LOGGER.warn("브랜드 이미지 확장자 거부: {}", name);
			return null;
		}
		Map<String, MultipartFile> one = new HashMap<String, MultipartFile>();
		one.put(field, mf);
		// 마지막 인자는 경로가 아니라 "프로퍼티 키" 다(EgovFileMngUtil.parseFileInf) — 브랜드 전용 폴더로 분리.
		// 폴더가 없으면 자동 생성된다. 기존 파일은 각 행에 경로가 기록돼 있어 영향받지 않는다.
		List<FileVO> result = fileUtil.parseFileInf(one, "BRD_", 0, "", STORE_PATH_KEY);
		if (result == null || result.isEmpty()) {
			return null;
		}
		return fileMngService.insertFileInfs(result);
	}

	/**
	 * 로고 이미지. 인증 없이 열어 둔다 — 로그인 화면 헤더에도 나와야 한다.
	 */
	@RequestMapping(value = "/cmm/brand/logo.do")
	public void logo(HttpServletResponse response) throws Exception {
		writeImage(response, BrandInfo.get().getLogoAtchFileId());
	}

	/**
	 * 파비콘 이미지. 인증 없이 열어 둔다.
	 */
	@RequestMapping(value = "/cmm/brand/favicon.do")
	public void favicon(HttpServletResponse response) throws Exception {
		writeImage(response, BrandInfo.get().getFaviconAtchFileId());
	}

	/** 첨부ID 의 파일 1건을 그대로 흘려보낸다. 없으면 404. */
	private void writeImage(HttpServletResponse response, String atchFileId) throws Exception {
		FileVO fvo = egovBrandService.selectBrandFile(atchFileId);
		if (fvo == null || fvo.getFileStreCours() == null || fvo.getStreFileNm() == null) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
			return;
		}
		File file = new File(fvo.getFileStreCours(), fvo.getStreFileNm());
		if (!file.exists() || !file.isFile()) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
			return;
		}
		response.setContentType(contentType(fvo.getFileExtsn()));
		response.setContentLength((int) file.length());
		// URL 에 ?v=최종수정시점 이 붙으므로 길게 캐시해도 교체 즉시 반영된다
		response.setHeader("Cache-Control", "public, max-age=3600");

		InputStream in = null;
		OutputStream out = null;
		try {
			in = new FileInputStream(file);
			out = response.getOutputStream();
			byte[] buf = new byte[8192];
			int len;
			while ((len = in.read(buf)) != -1) {
				out.write(buf, 0, len);
			}
			out.flush();
		} finally {
			if (in != null) {
				try {
					in.close();
				} catch (Exception ignore) {
					LOGGER.debug("brand image stream close ignored");
				}
			}
		}
	}

	private String contentType(String extsn) {
		String e = (extsn == null) ? "" : extsn.trim().toLowerCase();
		if ("svg".equals(e)) {
			return "image/svg+xml";
		}
		if ("png".equals(e)) {
			return "image/png";
		}
		if ("gif".equals(e)) {
			return "image/gif";
		}
		if ("ico".equals(e)) {
			return "image/x-icon";
		}
		if ("jpg".equals(e) || "jpeg".equals(e)) {
			return "image/jpeg";
		}
		return "application/octet-stream";
	}
}
