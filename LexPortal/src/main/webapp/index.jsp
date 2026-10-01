<%@ page language="java" contentType="text/html; charset=utf-8" pageEncoding="utf-8"%>
<%-- 루트 진입점 — /index.do 로 위임 (2026-08-04 포탈 모드).
     redirect 인 이유: SiteMesh 필터가 REQUEST 디스패치만 개입하므로 forward 로 가면
     "/" 요청 기준으로 데코레이터가 결정되어 /index.do* 데코 제외가 안 먹는다.
     포탈 모드(Globals.law.portalMain=Y, 기본)=공개 포탈 메인(비로그인 열람),
     관리기능 전용(N)=컨트롤러가 /main.do 로 재위임해 종전대로 로그인이 첫 화면. --%>
<% response.sendRedirect(request.getContextPath() + "/index.do"); %>
