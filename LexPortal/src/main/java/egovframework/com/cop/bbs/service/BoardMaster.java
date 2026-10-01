package egovframework.com.cop.bbs.service;

import java.io.Serializable;

import org.apache.commons.lang3.builder.ToStringBuilder;

/**
 *  게시판 속성정보를 담기위한 엔티티 클래스
 * @author 공통서비스개발팀 이삼섭
 * @since 2009.06.01
 * @version 1.0
 * @see
 *
 * <pre>
 * << 개정이력(Modification Information) >>
 *   
 *   수정일      수정자           수정내용
 *  -------    --------    ---------------------------
 *   2009.03.12  이삼섭          최초 생성
 *   2009.06.26  한성곤		2단계 기능 추가 (댓글관리, 만족도조사)
 *
 * </pre>
 */
@SuppressWarnings("serial")
public class BoardMaster implements Serializable {
    
    /** 게시판 아이디 */
    private String bbsId = "";
    
    /** 게시판 소개 */
    private String bbsIntrcn = "";
    
    /** 게시판 명 */
    private String bbsNm = "";
    
    /** 게시판 유형코드 */
    private String bbsTyCode = "";
    
    /** 파일첨부가능여부 */
    private String fileAtchPosblAt = "";
    
    /** 최초등록자 아이디 */
    private String frstRegisterId = "";
    
    /** 최초등록시점 */
    private String frstRegisterPnttm = "";
    
    /** 최종수정자 아이디 */
    public String lastUpdusrId = "";
    
    /** 최종수정시점 */
    private String lastUpdusrPnttm = "";
    
    /** 첨부가능파일숫자 */
    private int atchPosblFileNumber = 0;
    
    /** 첨부가능파일사이즈 */
    private String atchPosblFileSize = "";
    
    /** 답장가능여부 */
    private String replyPosblAt = "";
    
    /** 템플릿 아이디 */
    private String tmplatId = "";

    /** 게시판 스킨 코드 */
    private String bbsSkinCode = "BASIC";

    /** 여분필드 1 */
    private String bbsExtraField1 = "";

    /** 여분필드 2 */
    private String bbsExtraField2 = "";

    /** 여분필드 3 */
    private String bbsExtraField3 = "";

    /** 여분필드 4 */
    private String bbsExtraField4 = "";

    /** 여분필드 5 */
    private String bbsExtraField5 = "";

    /** 여분필드 6 */
    private String bbsExtraField6 = "";

    /** 여분필드 7 */
    private String bbsExtraField7 = "";

    /** 여분필드 8 */
    private String bbsExtraField8 = "";

    /** 여분필드 9 */
    private String bbsExtraField9 = "";

    /** 여분필드 10 */
    private String bbsExtraField10 = "";

    private String bbsExtraFieldType1 = "text";
    private String bbsExtraFieldType2 = "text";
    private String bbsExtraFieldType3 = "text";
    private String bbsExtraFieldType4 = "text";
    private String bbsExtraFieldType5 = "text";
    private String bbsExtraFieldType6 = "text";
    private String bbsExtraFieldType7 = "text";
    private String bbsExtraFieldType8 = "text";
    private String bbsExtraFieldType9 = "text";
    private String bbsExtraFieldType10 = "text";

    private String bbsExtraFieldCodeId1 = "";
    private String bbsExtraFieldCodeId2 = "";
    private String bbsExtraFieldCodeId3 = "";
    private String bbsExtraFieldCodeId4 = "";
    private String bbsExtraFieldCodeId5 = "";
    private String bbsExtraFieldCodeId6 = "";
    private String bbsExtraFieldCodeId7 = "";
    private String bbsExtraFieldCodeId8 = "";
    private String bbsExtraFieldCodeId9 = "";
    private String bbsExtraFieldCodeId10 = "";
    
    /** 사용여부 */
    private String useAt = "";
    
    /** 사용플래그 */
    private String bbsUseFlag = "";
    
    /** 대상 아이디 */
    private String trgetId = "";
    
    /** 등록구분코드 */
    private String registSeCode = "";
    
    /** 유일 아이디 */
    private String uniqId = "";
    
    /** 템플릿 명 */
    private String tmplatNm = "";
    
    /** 커뮤니티 ID */
    private String cmmntyId;
    
    /** 블로그 ID */
    private String blogId;
    
    /** 블로그 사용 유무 */
    private String blogAt;
    
    //---------------------------------
    // 2009.06.26 : 2단계 기능 추가
    //---------------------------------
    /** 추가 option (댓글-comment, 만족도조사-stsfdg) */
    private String option = "";
    
    /** 댓글 여부. ★DB 컬럼은 ANSWER_AT(EgovBBSAddedOptions 매퍼) — 이름은 "답변/답장" 처럼 읽히나 실제 의미는 '댓글'.
     *  별개 개념인 replyPosblAt(답장가능여부, REPLY_POSBL_AT)과 혼동 주의. */
    private String commentAt = "";
    
    /** 만족도조사 */
    private String stsfdgAt = "";
    ////-------------------------------

    //---------------------------------
    // 2026.07.15 : 게시판 표시·정책 속성 확장
    //---------------------------------
    /** 목록 페이지당 게시물 수 옵션(쉼표 목록). 빈값=전역 기본값, "10"=고정, "10,20,30"=사용자 select 선택 */
    private String listPageUnit = "";

    /** 비밀글 허용 여부(Y/N) — N 이면 작성 시 비밀글 설정 불가 */
    private String secretPosblAt = "Y";

    /** 리치텍스트 에디터(CKEditor) 사용 여부(Y/N) — N 이면 일반 텍스트 입력 */
    private String richEditorAt = "Y";

    /** 통합검색 노출 여부(Y/N) — N 이면 통합검색 결과에서 이 게시판 글을 제외 */
    private String searchIncldAt = "Y";

    /** 페이징 사용 여부(Y/N) — N 이면 전건을 한 페이지에 싣고 페이저를 숨김 */
    private String pagingAt = "Y";

    /** 목록 검색창 표시 여부(Y/N) — N 이면 목록 상단 검색 입력을 숨김 */
    private String searchBoxAt = "Y";
    ////-------------------------------

    /**
     * bbsId attribute를 리턴한다.
     * 
     * @return the bbsId
     */
    public String getBbsId() {
	return bbsId;
    }

    /**
     * bbsId attribute 값을 설정한다.
     * 
     * @param bbsId
     *            the bbsId to set
     */
    public void setBbsId(String bbsId) {
	this.bbsId = bbsId;
    }

    /**
     * bbsIntrcn attribute를 리턴한다.
     * 
     * @return the bbsIntrcn
     */
    public String getBbsIntrcn() {
	return bbsIntrcn;
    }

    /**
     * bbsIntrcn attribute 값을 설정한다.
     * 
     * @param bbsIntrcn
     *            the bbsIntrcn to set
     */
    public void setBbsIntrcn(String bbsIntrcn) {
	this.bbsIntrcn = bbsIntrcn;
    }

    /**
     * bbsNm attribute를 리턴한다.
     * 
     * @return the bbsNm
     */
    public String getBbsNm() {
	return bbsNm;
    }

    /**
     * bbsNm attribute 값을 설정한다.
     * 
     * @param bbsNm
     *            the bbsNm to set
     */
    public void setBbsNm(String bbsNm) {
	this.bbsNm = bbsNm;
    }

    /**
     * bbsTyCode attribute를 리턴한다.
     * 
     * @return the bbsTyCode
     */
    public String getBbsTyCode() {
	return bbsTyCode;
    }

    /**
     * bbsTyCode attribute 값을 설정한다.
     * 
     * @param bbsTyCode
     *            the bbsTyCode to set
     */
    public void setBbsTyCode(String bbsTyCode) {
	this.bbsTyCode = bbsTyCode;
    }

    /**
     * fileAtchPosblAt attribute를 리턴한다.
     * 
     * @return the fileAtchPosblAt
     */
    public String getFileAtchPosblAt() {
	return fileAtchPosblAt;
    }

    /**
     * fileAtchPosblAt attribute 값을 설정한다.
     * 
     * @param fileAtchPosblAt
     *            the fileAtchPosblAt to set
     */
    public void setFileAtchPosblAt(String fileAtchPosblAt) {
	this.fileAtchPosblAt = fileAtchPosblAt;
    }

    /**
     * frstRegisterId attribute를 리턴한다.
     * 
     * @return the frstRegisterId
     */
    public String getFrstRegisterId() {
	return frstRegisterId;
    }

    /**
     * frstRegisterId attribute 값을 설정한다.
     * 
     * @param frstRegisterId
     *            the frstRegisterId to set
     */
    public void setFrstRegisterId(String frstRegisterId) {
	this.frstRegisterId = frstRegisterId;
    }

    /**
     * frstRegisterPnttm attribute를 리턴한다.
     * 
     * @return the frstRegisterPnttm
     */
    public String getFrstRegisterPnttm() {
	return frstRegisterPnttm;
    }

    /**
     * frstRegisterPnttm attribute 값을 설정한다.
     * 
     * @param frstRegisterPnttm
     *            the frstRegisterPnttm to set
     */
    public void setFrstRegisterPnttm(String frstRegisterPnttm) {
	this.frstRegisterPnttm = frstRegisterPnttm;
    }

    /**
     * lastUpdusrId attribute를 리턴한다.
     * 
     * @return the lastUpdusrId
     */
    public String getLastUpdusrId() {
	return lastUpdusrId;
    }

    /**
     * lastUpdusrId attribute 값을 설정한다.
     * 
     * @param lastUpdusrId
     *            the lastUpdusrId to set
     */
    public void setLastUpdusrId(String lastUpdusrId) {
	this.lastUpdusrId = lastUpdusrId;
    }

    /**
     * lastUpdusrPnttm attribute를 리턴한다.
     * 
     * @return the lastUpdusrPnttm
     */
    public String getLastUpdusrPnttm() {
	return lastUpdusrPnttm;
    }

    /**
     * lastUpdusrPnttm attribute 값을 설정한다.
     * 
     * @param lastUpdusrPnttm
     *            the lastUpdusrPnttm to set
     */
    public void setLastUpdusrPnttm(String lastUpdusrPnttm) {
	this.lastUpdusrPnttm = lastUpdusrPnttm;
    }

    /**
     * atchPosblFileNumber attribute를 리턴한다.
     * 
     * @return the atchPosblFileNumber
     */
    public int getAtchPosblFileNumber() {
	return atchPosblFileNumber;
    }

    /**
     * atchPosblFileNumber attribute 값을 설정한다.
     * 
     * @param atchPosblFileNumber
     *            the atchPosblFileNumber to set
     */
    public void setAtchPosblFileNumber(int atchPosblFileNumber) {
	this.atchPosblFileNumber = atchPosblFileNumber;
    }

    /**
     * atchPosblFileSize attribute를 리턴한다.
     * 
     * @return the atchPosblFileSize
     */
    public String getAtchPosblFileSize() {
	return atchPosblFileSize;
    }

    /**
     * atchPosblFileSize attribute 값을 설정한다.
     * 
     * @param atchPosblFileSize
     *            the atchPosblFileSize to set
     */
    public void setAtchPosblFileSize(String atchPosblFileSize) {
	this.atchPosblFileSize = atchPosblFileSize;
    }

    /**
     * replyPosblAt attribute를 리턴한다.
     * 
     * @return the replyPosblAt
     */
    public String getReplyPosblAt() {
	return replyPosblAt;
    }

    /**
     * replyPosblAt attribute 값을 설정한다.
     * 
     * @param replyPosblAt
     *            the replyPosblAt to set
     */
    public void setReplyPosblAt(String replyPosblAt) {
	this.replyPosblAt = replyPosblAt;
    }

    /**
     * tmplatId attribute를 리턴한다.
     * 
     * @return the tmplatId
     */
    public String getTmplatId() {
	return tmplatId;
    }

    /**
     * tmplatId attribute 값을 설정한다.
     * 
     * @param tmplatId
     *            the tmplatId to set
     */
    public void setTmplatId(String tmplatId) {
	this.tmplatId = tmplatId;
    }

    /**
     * useAt attribute를 리턴한다.
     * 
     * @return the useAt
     */
    public String getUseAt() {
	return useAt;
    }

    /**
     * useAt attribute 값을 설정한다.
     * 
     * @param useAt
     *            the useAt to set
     */
    public void setUseAt(String useAt) {
	this.useAt = useAt;
    }

    /**
     * bbsUseFlag attribute를 리턴한다.
     * 
     * @return the bbsUseFlag
     */
    public String getBbsUseFlag() {
	return bbsUseFlag;
    }

    /**
     * bbsUseFlag attribute 값을 설정한다.
     * 
     * @param bbsUseFlag
     *            the bbsUseFlag to set
     */
    public void setBbsUseFlag(String bbsUseFlag) {
	this.bbsUseFlag = bbsUseFlag;
    }

    /**
     * trgetId attribute를 리턴한다.
     * 
     * @return the trgetId
     */
    public String getTrgetId() {
	return trgetId;
    }

    /**
     * trgetId attribute 값을 설정한다.
     * 
     * @param trgetId
     *            the trgetId to set
     */
    public void setTrgetId(String trgetId) {
	this.trgetId = trgetId;
    }

    /**
     * registSeCode attribute를 리턴한다.
     * 
     * @return the registSeCode
     */
    public String getRegistSeCode() {
	return registSeCode;
    }

    /**
     * registSeCode attribute 값을 설정한다.
     * 
     * @param registSeCode
     *            the registSeCode to set
     */
    public void setRegistSeCode(String registSeCode) {
	this.registSeCode = registSeCode;
    }

    /**
     * uniqId attribute를 리턴한다.
     * 
     * @return the uniqId
     */
    public String getUniqId() {
	return uniqId;
    }

    /**
     * uniqId attribute 값을 설정한다.
     * 
     * @param uniqId
     *            the uniqId to set
     */
    public void setUniqId(String uniqId) {
	this.uniqId = uniqId;
    }

    /**
     * tmplatNm attribute를 리턴한다.
     * 
     * @return the tmplatNm
     */
    public String getTmplatNm() {
	return tmplatNm;
    }

    /**
     * tmplatNm attribute 값을 설정한다.
     * 
     * @param tmplatNm
     *            the tmplatNm to set
     */
    public void setTmplatNm(String tmplatNm) {
	this.tmplatNm = tmplatNm;
    }

    public String getBbsSkinCode() {
        return bbsSkinCode;
    }

    public void setBbsSkinCode(String bbsSkinCode) {
        this.bbsSkinCode = bbsSkinCode;
    }

    public String getBbsExtraField1() {
        return bbsExtraField1;
    }

    public void setBbsExtraField1(String bbsExtraField1) {
        this.bbsExtraField1 = bbsExtraField1;
    }

    public String getBbsExtraField2() {
        return bbsExtraField2;
    }

    public void setBbsExtraField2(String bbsExtraField2) {
        this.bbsExtraField2 = bbsExtraField2;
    }

    public String getBbsExtraField3() {
        return bbsExtraField3;
    }

    public void setBbsExtraField3(String bbsExtraField3) {
        this.bbsExtraField3 = bbsExtraField3;
    }

    public String getBbsExtraField4() {
        return bbsExtraField4;
    }

    public void setBbsExtraField4(String bbsExtraField4) {
        this.bbsExtraField4 = bbsExtraField4;
    }

    public String getBbsExtraField5() {
        return bbsExtraField5;
    }

    public void setBbsExtraField5(String bbsExtraField5) {
        this.bbsExtraField5 = bbsExtraField5;
    }

    public String getBbsExtraField6() {
        return bbsExtraField6;
    }

    public void setBbsExtraField6(String bbsExtraField6) {
        this.bbsExtraField6 = bbsExtraField6;
    }

    public String getBbsExtraField7() {
        return bbsExtraField7;
    }

    public void setBbsExtraField7(String bbsExtraField7) {
        this.bbsExtraField7 = bbsExtraField7;
    }

    public String getBbsExtraField8() {
        return bbsExtraField8;
    }

    public void setBbsExtraField8(String bbsExtraField8) {
        this.bbsExtraField8 = bbsExtraField8;
    }

    public String getBbsExtraField9() {
        return bbsExtraField9;
    }

    public void setBbsExtraField9(String bbsExtraField9) {
        this.bbsExtraField9 = bbsExtraField9;
    }

    public String getBbsExtraField10() {
        return bbsExtraField10;
    }

    public void setBbsExtraField10(String bbsExtraField10) {
        this.bbsExtraField10 = bbsExtraField10;
    }

    public String getBbsExtraField(int idx) {
        switch (idx) {
        case 1: return bbsExtraField1;
        case 2: return bbsExtraField2;
        case 3: return bbsExtraField3;
        case 4: return bbsExtraField4;
        case 5: return bbsExtraField5;
        case 6: return bbsExtraField6;
        case 7: return bbsExtraField7;
        case 8: return bbsExtraField8;
        case 9: return bbsExtraField9;
        case 10: return bbsExtraField10;
        default: return "";
        }
    }

    public String getBbsExtraFieldType(int idx) {
        switch (idx) {
        case 1: return bbsExtraFieldType1;
        case 2: return bbsExtraFieldType2;
        case 3: return bbsExtraFieldType3;
        case 4: return bbsExtraFieldType4;
        case 5: return bbsExtraFieldType5;
        case 6: return bbsExtraFieldType6;
        case 7: return bbsExtraFieldType7;
        case 8: return bbsExtraFieldType8;
        case 9: return bbsExtraFieldType9;
        case 10: return bbsExtraFieldType10;
        default: return "text";
        }
    }

    public String getBbsExtraFieldCodeId(int idx) {
        switch (idx) {
        case 1: return bbsExtraFieldCodeId1;
        case 2: return bbsExtraFieldCodeId2;
        case 3: return bbsExtraFieldCodeId3;
        case 4: return bbsExtraFieldCodeId4;
        case 5: return bbsExtraFieldCodeId5;
        case 6: return bbsExtraFieldCodeId6;
        case 7: return bbsExtraFieldCodeId7;
        case 8: return bbsExtraFieldCodeId8;
        case 9: return bbsExtraFieldCodeId9;
        case 10: return bbsExtraFieldCodeId10;
        default: return "";
        }
    }

    public String getBbsExtraFieldType1() { return bbsExtraFieldType1; }
    public void setBbsExtraFieldType1(String bbsExtraFieldType1) { this.bbsExtraFieldType1 = normalizeExtraFieldType(bbsExtraFieldType1); }
    public String getBbsExtraFieldType2() { return bbsExtraFieldType2; }
    public void setBbsExtraFieldType2(String bbsExtraFieldType2) { this.bbsExtraFieldType2 = normalizeExtraFieldType(bbsExtraFieldType2); }
    public String getBbsExtraFieldType3() { return bbsExtraFieldType3; }
    public void setBbsExtraFieldType3(String bbsExtraFieldType3) { this.bbsExtraFieldType3 = normalizeExtraFieldType(bbsExtraFieldType3); }
    public String getBbsExtraFieldType4() { return bbsExtraFieldType4; }
    public void setBbsExtraFieldType4(String bbsExtraFieldType4) { this.bbsExtraFieldType4 = normalizeExtraFieldType(bbsExtraFieldType4); }
    public String getBbsExtraFieldType5() { return bbsExtraFieldType5; }
    public void setBbsExtraFieldType5(String bbsExtraFieldType5) { this.bbsExtraFieldType5 = normalizeExtraFieldType(bbsExtraFieldType5); }
    public String getBbsExtraFieldType6() { return bbsExtraFieldType6; }
    public void setBbsExtraFieldType6(String bbsExtraFieldType6) { this.bbsExtraFieldType6 = normalizeExtraFieldType(bbsExtraFieldType6); }
    public String getBbsExtraFieldType7() { return bbsExtraFieldType7; }
    public void setBbsExtraFieldType7(String bbsExtraFieldType7) { this.bbsExtraFieldType7 = normalizeExtraFieldType(bbsExtraFieldType7); }
    public String getBbsExtraFieldType8() { return bbsExtraFieldType8; }
    public void setBbsExtraFieldType8(String bbsExtraFieldType8) { this.bbsExtraFieldType8 = normalizeExtraFieldType(bbsExtraFieldType8); }
    public String getBbsExtraFieldType9() { return bbsExtraFieldType9; }
    public void setBbsExtraFieldType9(String bbsExtraFieldType9) { this.bbsExtraFieldType9 = normalizeExtraFieldType(bbsExtraFieldType9); }
    public String getBbsExtraFieldType10() { return bbsExtraFieldType10; }
    public void setBbsExtraFieldType10(String bbsExtraFieldType10) { this.bbsExtraFieldType10 = normalizeExtraFieldType(bbsExtraFieldType10); }

    public String getBbsExtraFieldCodeId1() { return bbsExtraFieldCodeId1; }
    public void setBbsExtraFieldCodeId1(String bbsExtraFieldCodeId1) { this.bbsExtraFieldCodeId1 = bbsExtraFieldCodeId1; }
    public String getBbsExtraFieldCodeId2() { return bbsExtraFieldCodeId2; }
    public void setBbsExtraFieldCodeId2(String bbsExtraFieldCodeId2) { this.bbsExtraFieldCodeId2 = bbsExtraFieldCodeId2; }
    public String getBbsExtraFieldCodeId3() { return bbsExtraFieldCodeId3; }
    public void setBbsExtraFieldCodeId3(String bbsExtraFieldCodeId3) { this.bbsExtraFieldCodeId3 = bbsExtraFieldCodeId3; }
    public String getBbsExtraFieldCodeId4() { return bbsExtraFieldCodeId4; }
    public void setBbsExtraFieldCodeId4(String bbsExtraFieldCodeId4) { this.bbsExtraFieldCodeId4 = bbsExtraFieldCodeId4; }
    public String getBbsExtraFieldCodeId5() { return bbsExtraFieldCodeId5; }
    public void setBbsExtraFieldCodeId5(String bbsExtraFieldCodeId5) { this.bbsExtraFieldCodeId5 = bbsExtraFieldCodeId5; }
    public String getBbsExtraFieldCodeId6() { return bbsExtraFieldCodeId6; }
    public void setBbsExtraFieldCodeId6(String bbsExtraFieldCodeId6) { this.bbsExtraFieldCodeId6 = bbsExtraFieldCodeId6; }
    public String getBbsExtraFieldCodeId7() { return bbsExtraFieldCodeId7; }
    public void setBbsExtraFieldCodeId7(String bbsExtraFieldCodeId7) { this.bbsExtraFieldCodeId7 = bbsExtraFieldCodeId7; }
    public String getBbsExtraFieldCodeId8() { return bbsExtraFieldCodeId8; }
    public void setBbsExtraFieldCodeId8(String bbsExtraFieldCodeId8) { this.bbsExtraFieldCodeId8 = bbsExtraFieldCodeId8; }
    public String getBbsExtraFieldCodeId9() { return bbsExtraFieldCodeId9; }
    public void setBbsExtraFieldCodeId9(String bbsExtraFieldCodeId9) { this.bbsExtraFieldCodeId9 = bbsExtraFieldCodeId9; }
    public String getBbsExtraFieldCodeId10() { return bbsExtraFieldCodeId10; }
    public void setBbsExtraFieldCodeId10(String bbsExtraFieldCodeId10) { this.bbsExtraFieldCodeId10 = bbsExtraFieldCodeId10; }

    /**
     * 여분필드 입력타입 정규화. text 외의 타입(radio/select/checkbox)은 공통코드가 붙어야 위젯으로 그려지고,
     * 코드ID 가 비어 있으면 화면이 text 로 떨어뜨린다(선택지 없는 라디오는 의미가 없다).
     */
    private String normalizeExtraFieldType(String type) {
        if ("radio".equals(type) || "select".equals(type) || "checkbox".equals(type)) {
            return type;
        }
        return "text";
    }

    /** 여러 값을 고를 수 있는 타입인가 — 값은 쉼표로 이어 NTT_EXTRA_FIELD_n 한 칸에 저장한다. */
    public boolean isMultiValueExtraField(int idx) {
        return "checkbox".equals(getBbsExtraFieldType(idx));
    }

    /**
     * option attribute를 리턴한다.
     * @return the option
     */
    public String getOption() {
        return option;
    }

    /**
     * option attribute 값을 설정한다.
     * @param option the option to set
     */
    public void setOption(String option) {
        this.option = option;
    }

    /**
     * commentAt attribute를 리턴한다.
     * @return the commentAt
     */
    public String getCommentAt() {
        return commentAt;
    }

    /**
     * commentAt attribute 값을 설정한다.
     * @param commentAt the commentAt to set
     */
    public void setCommentAt(String commentAt) {
        this.commentAt = commentAt;
    }

    /**
     * stsfdgAt attribute를 리턴한다.
     * @return the stsfdgAt
     */
    public String getStsfdgAt() {
        return stsfdgAt;
    }

    /**
     * stsfdg attribute 값을 설정한다.
     * @param stsfdgAt the stsfdgAt to set
     */
    public void setStsfdgAt(String stsfdgAt) {
        this.stsfdgAt = stsfdgAt;
    }

    /** 목록 페이지당 게시물 수 옵션(쉼표 목록). 빈값=전역, "10"=고정, "10,20,30"=사용자 select. */
    public String getListPageUnit() {
        return listPageUnit;
    }

    public void setListPageUnit(String listPageUnit) {
        this.listPageUnit = listPageUnit;
    }

    /** 비밀글 허용 여부(Y/N). */
    public String getSecretPosblAt() {
        return secretPosblAt;
    }

    public void setSecretPosblAt(String secretPosblAt) {
        this.secretPosblAt = secretPosblAt;
    }

    /** 리치텍스트 에디터 사용 여부(Y/N). */
    public String getRichEditorAt() {
        return richEditorAt;
    }

    public void setRichEditorAt(String richEditorAt) {
        this.richEditorAt = richEditorAt;
    }

    /** 통합검색 노출 여부(Y/N). */
    public String getSearchIncldAt() {
        return searchIncldAt;
    }

    public void setSearchIncldAt(String searchIncldAt) {
        this.searchIncldAt = searchIncldAt;
    }

    /** 페이징 사용 여부(Y/N). */
    public String getPagingAt() {
        return pagingAt;
    }

    public void setPagingAt(String pagingAt) {
        this.pagingAt = pagingAt;
    }

    /** 목록 검색창 표시 여부(Y/N). */
    public String getSearchBoxAt() {
        return searchBoxAt;
    }

    public void setSearchBoxAt(String searchBoxAt) {
        this.searchBoxAt = searchBoxAt;
    }

    /**
     * cmmntyId attribute를 리턴한다.
     * @return the cmmntyId
     */
    public String getCmmntyId() {
    	return cmmntyId;
    }
    
    /**
     * cmmntyId attribute 값을 설정한다.
     * @param cmmntyId the cmmntyId to set
     */
    public void setCmmntyId(String cmmntyId) {
    	this.cmmntyId = cmmntyId;
    }

    public String getBlogId() {
		return blogId;
	}

	public void setBlogId(String blogId) {
		this.blogId = blogId;
	}

	public String getBlogAt() {
		return blogAt;
	}

	public void setBlogAt(String blogAt) {
		this.blogAt = blogAt;
	}

	//---------------------------------
	// 사용자 메뉴 노출 설정 (2026-07-10)
	//   COMTNBBSMASTER 의 컬럼이 아니라, 게시판 저장과 함께 표준 메뉴 3테이블
	//   (COMTNPROGRMLIST/COMTNMENUINFO/COMTNMENUCREATDTLS)에 반영되는 입력값이다.
	//---------------------------------

	/** 사용자 GNB 노출 여부 (Y/N) */
	private String menuExposeAt = "N";

	/** 노출할 메뉴명 — 비우면 게시판명을 쓴다. */
	private String menuNm = "";

	/** 게시판 폴더 안에서의 정렬 순서 — 비우면 마지막에 붙인다. */
	private Integer menuOrdr;

	/** 이 게시판을 열람할 역할들 (ROLE_ADMIN 은 서버가 항상 포함) */
	private String[] menuAuthorCodes;

	public String getMenuExposeAt() {
		return menuExposeAt;
	}

	public void setMenuExposeAt(String menuExposeAt) {
		this.menuExposeAt = menuExposeAt;
	}

	public String getMenuNm() {
		return menuNm;
	}

	public void setMenuNm(String menuNm) {
		this.menuNm = menuNm;
	}

	public Integer getMenuOrdr() {
		return menuOrdr;
	}

	public void setMenuOrdr(Integer menuOrdr) {
		this.menuOrdr = menuOrdr;
	}

	public String[] getMenuAuthorCodes() {
		return (menuAuthorCodes == null) ? null : menuAuthorCodes.clone();
	}

	public void setMenuAuthorCodes(String[] menuAuthorCodes) {
		this.menuAuthorCodes = (menuAuthorCodes == null) ? null : menuAuthorCodes.clone();
	}

	/**
	 * 이 게시판에 글을 쓸 수 있는 역할들 (COMTNBBSWRITEAUTHOR, ROLE_ADMIN 은 서버가 항상 포함).
	 * 열람권한과 직교하는 축이다 — 열람만 되는 게시판과 쓰기까지 되는 게시판을 나눈다.
	 */
	private String[] writeAuthorCodes;

	public String[] getWriteAuthorCodes() {
		return (writeAuthorCodes == null) ? null : writeAuthorCodes.clone();
	}

	public void setWriteAuthorCodes(String[] writeAuthorCodes) {
		this.writeAuthorCodes = (writeAuthorCodes == null) ? null : writeAuthorCodes.clone();
	}

	/**
     * toString 메소드를 대치한다.
     */
    public String toString() {
	return ToStringBuilder.reflectionToString(this);
    }
}
