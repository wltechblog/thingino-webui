#!/usr/bin/haserl
<%in p/common.cgi %>
<% page_title="Diagnostic messages" %>
<%in p/header.cgi %>
<%
ex "/bin/dmesg"
button_refresh
%>
<%in p/footer.cgi %>
