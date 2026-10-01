/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/readduty/web/ReadDutyController.java
 *
 * 필수 열람(의무 숙지) — 지정 API (승인관리 목록의 지정 모달이 호출).
 *  - 지정/삭제/사용자검색 = 승인권한(APPROVER/ADMIN) — 승인 화면과 동일 기준(PromWorkController 관례).
 *  - 숙지 확인(confirmDuty)은 대상자 본인 액션 — 뷰어(FullTextController 쪽)에서 진입, 여기서는
 *    dutyConfirm.do 한 개만 열어 두고 서비스가 대상 재검증한다.
 */
package narainet.rlms.readduty.web;

import java.io.IOException;
import java.io.PrintWriter;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;

import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.rlms.readduty.service.ReadDutyService;
import narainet.rlms.readduty.service.ReadDutyTgtVO;
import narainet.rlms.readduty.service.ReadDutyVO;

@Controller
public class ReadDutyController {

	@Resource(name = "readDutyService")
	private ReadDutyService readDutyService;

	/** 승인권한(APPROVER/ADMIN) — RoleHierarchy 미확장(사용자당 1역할)이라 ROLE_ADMIN 명시 열거 */
	private static boolean hasApproverRole() {
		List<String> auths = EgovUserDetailsHelper.getAuthorities();
		return auths != null && (auths.contains("ROLE_ADMIN") || auths.contains("ROLE_APPROVER"));
	}

	private static void assertApprover() {
		if (!hasApproverRole()) {
			throw new AccessDeniedException("필수 열람 지정은 승인자(APPROVER) 또는 관리자만 할 수 있습니다.");
		}
	}

	/** 회차의 기존 지정 조회 — 지정 모달 로드 (없으면 duty=null) */
	@ResponseBody
	@RequestMapping("/rlms/readduty/dutyInfoJson.do")
	public Map<String, Object> dutyInfoJson(@RequestParam("promNo") Long promNo) {
		Map<String, Object> out = new HashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated()) || !hasApproverRole()) {
			out.put("success", false);
			return out;
		}
		ReadDutyVO duty = readDutyService.selectDutyByPromNo(promNo);
		out.put("success", true);
		if (duty != null) {
			Map<String, Object> d = new HashMap<>();
			d.put("dutyNo", duty.getDutyNo());
			d.put("allYn", duty.getAllYn());
			d.put("dueDt", duty.getDueDt());
			d.put("insNm", duty.getInsNm());
			d.put("insDt", duty.getInsDt());
			out.put("duty", d);
			List<Map<String, Object>> tgts = new ArrayList<>();
			if (duty.getTgtList() != null) {
				for (ReadDutyTgtVO t : duty.getTgtList()) {
					Map<String, Object> m = new HashMap<>();
					m.put("tgtTy", t.getTgtTy());
					m.put("tgtId", t.getTgtId());
					m.put("tgtNm", t.getTgtNm());
					tgts.add(m);
				}
			}
			out.put("tgtList", tgts);
		}
		return out;
	}

	/** 지정 저장 (upsert) — allYn='Y' 전사 / tgt 반복 파라미터 "DEPT:ORGNZT_ID"/"USER:ESNTL_ID" */
	@ResponseBody
	@RequestMapping(value = "/rlms/readduty/saveDuty.do", method = RequestMethod.POST)
	public Map<String, Object> saveDuty(@RequestParam("promNo") Long promNo,
			@RequestParam(value = "allYn", required = false, defaultValue = "N") String allYn,
			@RequestParam(value = "dueDt", required = false) String dueDt,
			@RequestParam(value = "tgt", required = false) List<String> tgts) {

		Map<String, Object> out = new HashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			out.put("success", false);
			out.put("message", "로그인이 필요합니다.");
			return out;
		}
		assertApprover();

		ReadDutyVO vo = new ReadDutyVO();
		vo.setPromNo(promNo);
		vo.setAllYn("Y".equals(allYn) ? "Y" : "N");
		vo.setDueDt(normalizeDate(dueDt));
		LoginVO user = (LoginVO) EgovUserDetailsHelper.getAuthenticatedUser();
		if (user != null) {
			vo.setInsId(user.getId());
			vo.setInsNm(user.getName());
		}
		try {
			readDutyService.saveDuty(vo, tgts);
			out.put("success", true);
			out.put("dutyNo", vo.getDutyNo());
		} catch (IllegalStateException e) {
			out.put("success", false);
			out.put("message", e.getMessage());
		} catch (Exception e) {
			out.put("success", false);
			out.put("message", "저장 중 오류가 발생했습니다.");
		}
		return out;
	}

	/** 지정 삭제 — 의무 철회(확인 기록 포함 제거) */
	@ResponseBody
	@RequestMapping(value = "/rlms/readduty/deleteDuty.do", method = RequestMethod.POST)
	public Map<String, Object> deleteDuty(@RequestParam("dutyNo") Long dutyNo) {
		Map<String, Object> out = new HashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			out.put("success", false);
			return out;
		}
		assertApprover();
		try {
			readDutyService.deleteDuty(dutyNo);
			out.put("success", true);
		} catch (Exception e) {
			out.put("success", false);
			out.put("message", "삭제 중 오류가 발생했습니다.");
		}
		return out;
	}

	/** 숙지 확인(2단계, 최종 증빙) — 뷰어 [숙지 확인] 버튼. 대상 여부는 서비스가 재검증(직접 POST 방어) */
	@ResponseBody
	@RequestMapping(value = "/rlms/readduty/confirmDuty.do", method = RequestMethod.POST)
	public Map<String, Object> confirmDuty(@RequestParam("dutyNo") Long dutyNo) {
		Map<String, Object> out = new HashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			out.put("success", false);
			out.put("message", "로그인이 필요합니다.");
			return out;
		}
		LoginVO user = (LoginVO) EgovUserDetailsHelper.getAuthenticatedUser();
		try {
			readDutyService.confirmDuty(dutyNo, user.getUniqId(), user.getName(),
					user.getOrgnztId(), user.getUserSe());
			out.put("success", true);
		} catch (IllegalStateException e) {
			out.put("success", false);
			out.put("message", e.getMessage());
		} catch (Exception e) {
			out.put("success", false);
			out.put("message", "처리 중 오류가 발생했습니다.");
		}
		return out;
	}

	/** 개인 대상 지정용 사용자 검색 — 개인정보(이름/아이디/부서) 조회라 지정 권한자만 */
	@ResponseBody
	@RequestMapping("/rlms/readduty/userSearchJson.do")
	public Map<String, Object> userSearchJson(
			@RequestParam(value = "keyword", required = false) String keyword) {
		Map<String, Object> out = new HashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated()) || !hasApproverRole()) {
			out.put("success", false);
			return out;
		}
		String kw = keyword == null ? "" : keyword.trim();
		if (kw.isEmpty()) {
			out.put("success", true);
			out.put("resultList", new ArrayList<>());
			return out;
		}
		out.put("success", true);
		out.put("resultList", readDutyService.selectUserSearch(kw));
		return out;
	}

	/** input[type=date] "YYYY-MM-DD" → "YYYYMMDD". 그 외/빈값 = null(무기한) */
	private static String normalizeDate(String d) {
		if (d == null) {
			return null;
		}
		String v = d.trim().replace("-", "");
		return v.matches("\\d{8}") ? v : null;
	}

	// ────────────────────────────────────────────────────────────────
	// 필수열람 현황 (컴플라이언스 증빙) — 메뉴 45050000, ADMIN/EDITOR/APPROVER
	// ────────────────────────────────────────────────────────────────

	private static boolean hasStatusRole() {
		List<String> auths = EgovUserDetailsHelper.getAuthorities();
		return auths != null && (auths.contains("ROLE_ADMIN")
				|| auths.contains("ROLE_EDITOR") || auths.contains("ROLE_APPROVER"));
	}

	private static void assertStatusRole() {
		if (!hasStatusRole()) {
			throw new AccessDeniedException("필수열람 현황은 관리자/작성자/승인자만 열람할 수 있습니다.");
		}
	}

	/** 현황 화면 — 지정건 목록 + (dutyNo 선택 시) 부서별 집계·개인 매트릭스 */
	@RequestMapping("/rlms/readduty/dutyStatus.do")
	public String dutyStatus(@RequestParam(value = "keyword", required = false) String keyword,
			@RequestParam(value = "dutyNo", required = false) Long dutyNo, ModelMap model) {

		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return "redirect:/uat/uia/egovLoginUsr.do";
		}
		assertStatusRole();

		String kw = (keyword == null || keyword.trim().isEmpty()) ? null : keyword.trim();
		model.addAttribute("keyword", kw);
		model.addAttribute("dutyList", readDutyService.selectDutyStatList(kw));
		if (dutyNo != null) {
			Map<String, Object> summary = readDutyService.selectDutySummary(dutyNo);
			if (summary != null) {
				model.addAttribute("dutySummary", summary);
				model.addAttribute("deptSummary", readDutyService.selectDutyDeptSummary(dutyNo));
				model.addAttribute("userMatrix", readDutyService.selectDutyUserMatrix(dutyNo));
			}
		}
		return "rlms/readduty/dutyStatus";
	}

	/** 현황 엑셀 — HTML 테이블 → .xls (POI 미사용 관행), UTF-8 BOM, 셀 텍스트 강제 */
	@RequestMapping("/rlms/readduty/dutyStatusExcel.do")
	public void dutyStatusExcel(@RequestParam("dutyNo") Long dutyNo,
			HttpServletResponse response) throws IOException {

		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated()) || !hasStatusRole()) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		Map<String, Object> summary = readDutyService.selectDutySummary(dutyNo);
		if (summary == null) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
			return;
		}
		List<Map<String, Object>> dept = readDutyService.selectDutyDeptSummary(dutyNo);
		List<Map<String, Object>> matrix = readDutyService.selectDutyUserMatrix(dutyNo);

		String fname = URLEncoder.encode("필수열람현황.xls", "UTF-8").replaceAll("\\+", "%20");
		response.setContentType("application/vnd.ms-excel; charset=UTF-8");
		response.setHeader("Content-Disposition",
				"attachment; filename=\"" + fname + "\"; filename*=UTF-8''" + fname);
		PrintWriter w = response.getWriter();
		w.print((char) 0xFEFF);
		w.print("<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"></head><body>");

		w.print("<table border=\"1\"><tr><th>규정명</th><th>개정일</th><th>대상</th><th>기한</th><th>지정자</th><th>지정일</th></tr>");
		w.print("<tr>" + xcell(summary.get("title")) + xcell(summary.get("promDate"))
				+ xcell("Y".equals(summary.get("allYn")) ? "전사(전 직원)" : "부서/개인 지정")
				+ xcell(summary.get("dueDt") == null ? "무기한" : summary.get("dueDt"))
				+ xcell(summary.get("insNm")) + xcell(summary.get("insDt")) + "</tr></table><br>");

		w.print("<table border=\"1\"><tr><th>부서</th><th>대상</th><th>열람</th><th>숙지</th><th>숙지율(%)</th></tr>");
		if (dept != null) {
			for (Map<String, Object> d : dept) {
				long tgt = toLong(d.get("tgtCnt")), conf = toLong(d.get("confCnt"));
				w.print("<tr>" + xcell(d.get("orgnztNm")) + xcell(d.get("tgtCnt"))
						+ xcell(d.get("readCnt")) + xcell(d.get("confCnt"))
						+ xcell(tgt > 0 ? String.valueOf(conf * 100 / tgt) : "0") + "</tr>");
			}
		}
		w.print("</table><br>");

		w.print("<table border=\"1\"><tr><th>부서</th><th>이름</th><th>아이디</th><th>열람일시</th><th>숙지일시</th><th>상태</th></tr>");
		if (matrix != null) {
			for (Map<String, Object> m : matrix) {
				String st = m.get("confDt") != null ? "숙지 완료" : (m.get("readDt") != null ? "열람(숙지 전)" : "미열람");
				w.print("<tr>" + xcell(m.get("orgnztNm")) + xcell(m.get("userNm")) + xcell(m.get("userId"))
						+ xcell(m.get("readDtFmt")) + xcell(m.get("confDtFmt")) + xcell(st) + "</tr>");
			}
		}
		w.print("</table></body></html>");
		w.flush();
	}

	private static long toLong(Object v) {
		return v instanceof Number ? ((Number) v).longValue() : 0L;
	}

	/** 엑셀 셀 — mso-number-format 텍스트 강제(긴 숫자 지수표기 방지) + HTML 이스케이프 */
	private static String xcell(Object v) {
		return "<td style=\"mso-number-format:'\\@'\">" + xesc(v) + "</td>";
	}

	private static String xesc(Object v) {
		return v == null ? "" : String.valueOf(v)
				.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
	}
}
