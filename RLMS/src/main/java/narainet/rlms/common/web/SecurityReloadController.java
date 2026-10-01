/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/common/web/SecurityReloadController.java
 *
 * 보안 URL 권한설정 재적용(reload) — 재시작 없이 COMTNROLEINFO/RELATE 변경을 즉시 반영.
 *   eGov EgovReloadableFilterInvocationSecurityMetadataSource.reload() 를 호출.
 *   권한 부여 화면(역할관리 등)의 "보안 적용" 버튼에서 Ajax 로 호출.
 */
package narainet.rlms.common.web;

import java.util.LinkedHashMap;
import java.util.Map;

import javax.annotation.Resource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import org.egovframe.rte.fdl.security.intercept.EgovReloadableFilterInvocationSecurityMetadataSource;

import egovframework.com.uss.ion.brd.service.BrandInfo;
import egovframework.com.uss.ion.brd.service.EgovBrandService;
import narainet.rlms.menu.MenuHelper;

/**
 * 보안 권한설정 재적용 Controller
 *
 * <pre>
 * << 개정이력 >>
 *   2026.06.09   RLMS 전환팀   최초 생성 (URL 권한 변경 후 재시작 없이 reload)
 * </pre>
 */
@Controller
public class SecurityReloadController {

	private static final Logger LOGGER = LoggerFactory.getLogger(SecurityReloadController.class);

	/** eGov 재적용 가능 보안 메타데이터 소스 (egov-security:config 가 등록) */
	@Autowired(required = false)
	private EgovReloadableFilterInvocationSecurityMetadataSource securityMetadataSource;

	/** 브랜드설정(로고·파비콘) — DB 직접 수정분을 다시 읽을 때 사용 */
	@Resource(name = "egovBrandService")
	private EgovBrandService egovBrandService;

	/** URL 권한설정 재적용 — 관리자만. 재시작 불필요. */
	@PreAuthorize("hasRole('ADMIN')")
	@ResponseBody
	@RequestMapping("/rlms/mgr/reloadSecurity.do")
	public Map<String, Object> reload() {
		Map<String, Object> res = new LinkedHashMap<>();
		try {
			if (securityMetadataSource == null) {
				res.put("success", false);
				res.put("message", "보안 메타데이터 소스를 찾을 수 없습니다. (재시작 필요)");
				return res;
			}
			securityMetadataSource.reload();
			res.put("success", true);
			res.put("message", "보안 권한설정을 재적용했습니다. (재시작 없이 즉시 반영)");
			LOGGER.info("Security URL metadata reloaded by admin.");
		} catch (Exception e) {
			LOGGER.warn("Security reload failed.", e);
			res.put("success", false);
			res.put("message", "재적용 실패: " + e.getMessage());
		}
		return res;
	}

	/** 메뉴 캐시 비우기 — 메뉴/권한매핑(COMTNMENUINFO·COMTNMENUCREATDTLS) 변경 즉시 GNB 반영. 관리자만. */
	@PreAuthorize("hasRole('ADMIN')")
	@ResponseBody
	@RequestMapping("/rlms/mgr/reloadMenu.do")
	public Map<String, Object> reloadMenu() {
		Map<String, Object> res = new LinkedHashMap<>();
		try {
			MenuHelper.clearCache();
			res.put("success", true);
			res.put("message", "메뉴 캐시를 비웠습니다. (변경한 메뉴가 즉시 반영됩니다)");
			LOGGER.info("Menu cache cleared by admin.");
		} catch (Exception e) {
			LOGGER.warn("Menu cache clear failed.", e);
			res.put("success", false);
			res.put("message", "메뉴 새로고침 실패: " + e.getMessage());
		}
		return res;
	}

	/** 브랜드설정 캐시 갱신 — 화면(브랜드설정)에서 저장하면 자동 갱신되지만,
	 *  COM_BRAND 를 DB 에서 직접 고친 경우엔 앱이 알 수 없으므로 이 엔드포인트로 다시 읽는다.
	 *  (메뉴 캐시 reloadMenu.do 와 같은 취지 — 재시작 불필요) 관리자만. */
	@PreAuthorize("hasRole('ADMIN')")
	@ResponseBody
	@RequestMapping("/rlms/mgr/reloadBrand.do")
	public Map<String, Object> reloadBrand() {
		Map<String, Object> res = new LinkedHashMap<>();
		try {
			BrandInfo.set(egovBrandService.selectBrand());
			res.put("success", true);
			res.put("message", "브랜드설정을 다시 읽었습니다. (로고·파비콘이 즉시 반영됩니다)");
			LOGGER.info("Brand cache reloaded by admin.");
		} catch (Exception e) {
			LOGGER.warn("Brand cache reload failed.", e);
			res.put("success", false);
			res.put("message", "브랜드설정 새로고침 실패: " + e.getMessage());
		}
		return res;
	}
}
