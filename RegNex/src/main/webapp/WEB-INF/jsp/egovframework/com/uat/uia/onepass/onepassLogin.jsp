<%@ page contentType="text/html; charset=utf-8"%>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<c:set var="pageHead">
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
<meta http-equiv="X-UA-Compatible" content="IE=Edge;"/>
</c:set>
<lay:layout head="${pageHead}">
<form id="onepassForm" method="post" action="${redirectUrl}">
<input type="hidden" name="${inputName}" value="${inputValue}"/>
<input type="hidden" name="pageType" value="${pageType}"/>
</form>
<script type="text/javascript">
document.getElementById('onepassForm').submit();
</script>
</lay:layout>
