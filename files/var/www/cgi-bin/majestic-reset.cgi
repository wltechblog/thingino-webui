#!/usr/bin/haserl
<%in _common.cgi %>
<%
command="cp /rom/etc/majestic.yaml /etc/majestic.yaml"
output=$(cp /rom/etc/majestic.yaml /etc/majestic.yaml 2>&1)
result=$?
if [ "0" -ne "$result" ]; then %>
<%in _header.cgi %>
<% report_command_error "$command" "$output" %>
<%in _footer.cgi %>
<% else
  redirect_to "/cgi-bin/updates.cgi"
fi
%>