#!/usr/bin/python

################################################################################################################
#
# Description:  This script send email with the log file attached
# Usage:        python mail.py <RECIPIENT EMAIL>
# Author:       Huy Quang Nguyen
# Created on:   08/08/2019
# Version:      1.0 Initial Creation
#
################################################################################################################

import sys
import os
from datetime import date

# Send an HTML email with an embedded image and a plain text message for
# email clients that don't want to display the HTML.

from email.MIMEMultipart import MIMEMultipart
from email.MIMEText import MIMEText
from email.MIMEImage import MIMEImage
from email.MIMEBase import MIMEBase
from email import Encoders

today = date.today()
sdate = today.strftime("%Y%m%d")

# Define these once; use them twice!
RECIPIENT=sys.argv[1]
strFrom = 'noreply-lbnauto@dfs.com'
strTo = RECIPIENT 

# Create the root message and fill in the from, to, and subject headers
msgRoot = MIMEMultipart('related')
msgRoot['Subject'] = 'AS400 Disk Space Report'
msgRoot['From'] = strFrom
msgRoot['To'] = strTo
#msgRoot.preamble = 'This is a multi-part message in MIME format.'

# Encapsulate the plain and HTML versions of the message body in an
# 'alternative' part, so message agents can decide which they want to display.
msgAlternative = MIMEMultipart('alternative')
msgRoot.attach(msgAlternative)

#msgText = MIMEText('This is the alternative plain text message.')
#msgAlternative.attach(msgText)

# We reference the image in the IMG SRC attribute by the ID we give it below
email_body = """\
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
<style>
table, th, td {
border: 1px solid black;
border-collapse: collapse;
}
th, td {
padding: 5px;
text-align: left;
}
</style>
</head>
<body>
"""
email_body += """\
<b>Please find disk space report for AS400 prod servers as the attachment.</b><br><br>
"""
email_body += """\
<i>End of Report</i>
</body>
</html>
"""
msgText = MIMEText(email_body, 'html')

msgAlternative.attach(msgText)

part = MIMEBase('application', "octet-stream")
part.set_payload( open('/home/as400auto/logs/as400_prtdskinf/prtdskinf_%s.log.gz' % sdate,"rb").read())
Encoders.encode_base64(part)
part.add_header('Content-Disposition', 'attachment; filename="%s"'
                % os.path.basename('prtdskinf_%s.log.gz' % sdate))
msgRoot.attach(part)

# Send the email (this example assumes SMTP authentication is required)
import smtplib
smtp = smtplib.SMTP()
smtp.connect('smtprelaysg.dfs.com:25')
#smtp.login('exampleuser', 'examplepass')
smtp.sendmail(strFrom, strTo, msgRoot.as_string())
smtp.quit()
