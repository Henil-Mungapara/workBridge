"""
Build complete 51-page WorkBridge Project Report in HTML and compile to PDF via Chrome headless.
"""

import os
import base64
import subprocess

REPORT_DIR = r"e:\workbridge"
DIAGRAMS_DIR = r"e:\workbridge\report_assets\diagrams"
SCREENS_DIR = r"e:\workbridge\report_assets\screens"
CHROME_PATH = r"C:\Program Files\Google\Chrome\Application\chrome.exe"

def b64_img(path):
    if not os.path.exists(path):
        return ""
    ext = os.path.splitext(path)[1].lower()
    mime = "image/jpeg" if ext in (".jpg", ".jpeg") else "image/png"
    with open(path, "rb") as f:
        data = f.read()
    return f"data:{mime};base64,{base64.b64encode(data).decode('utf-8')}"

# Load Logos
logo_rku_top = b64_img(r"e:\workbridge\extracted_pdf_images\img_0.jpg")
logo_rku_bottom = b64_img(r"e:\workbridge\extracted_pdf_images\img_1.jpg")
logo_workbridge = b64_img(r"E:\workBridgeDoc\Logo\workbridge-icon-whitebg-2048.png")

# Load Diagrams
diag_er = b64_img(os.path.join(DIAGRAMS_DIR, "er_diagram.png"))
diag_usecase = b64_img(os.path.join(DIAGRAMS_DIR, "usecase_diagram.png"))
diag_dfd = b64_img(os.path.join(DIAGRAMS_DIR, "dfd_diagram.png"))
diag_flowchart = b64_img(os.path.join(DIAGRAMS_DIR, "flowchart_diagram.png"))

# Load Screenshots
screen_home = b64_img(os.path.join(SCREENS_DIR, "screen_home.png"))
screen_auth = b64_img(os.path.join(SCREENS_DIR, "screen_auth.png"))
screen_password = b64_img(os.path.join(SCREENS_DIR, "screen_password.png"))
screen_catalog = b64_img(os.path.join(SCREENS_DIR, "screen_catalog.png"))
screen_provider_details = b64_img(os.path.join(SCREENS_DIR, "screen_provider_details.png"))
screen_booking_modal = b64_img(os.path.join(SCREENS_DIR, "screen_booking_modal.png"))
screen_checkout = b64_img(os.path.join(SCREENS_DIR, "screen_checkout.png"))
screen_profile = b64_img(os.path.join(SCREENS_DIR, "screen_profile.png"))
screen_lifecycle = b64_img(os.path.join(SCREENS_DIR, "screen_lifecycle.png"))
screen_tracking_map = b64_img(os.path.join(SCREENS_DIR, "screen_tracking_map.png"))
screen_flex = b64_img(os.path.join(SCREENS_DIR, "screen_flex.png"))
screen_safe = b64_img(os.path.join(SCREENS_DIR, "screen_safe.png"))
screen_admin_dashboard = b64_img(os.path.join(SCREENS_DIR, "screen_admin_dashboard.png"))
screen_admin_data = b64_img(os.path.join(SCREENS_DIR, "screen_admin_data.png"))
screen_karigar = b64_img(os.path.join(SCREENS_DIR, "screen_karigar.png"))

print("All images and logos loaded into base64.")

# Master CSS for the Academic Report
HTML_HEAD = """<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>WorkBridge - Project Report</title>
<style>
  @page {
    size: A4 portrait;
    margin: 0;
  }
  html, body {
    margin: 0;
    padding: 0;
    background: #525659;
    font-family: 'Times New Roman', Times, serif;
    color: #000000;
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }
  .page {
    width: 210mm;
    height: 297mm;
    margin: 0 auto;
    background: #ffffff;
    box-sizing: border-box;
    padding: 12mm 15mm;
    page-break-after: always;
    page-break-inside: avoid;
    position: relative;
    overflow: hidden;
  }
  .page-inner {
    width: 100%;
    height: 100%;
    border: 3.5px double #000000;
    box-sizing: border-box;
    padding: 16mm 18mm 14mm 18mm;
    position: relative;
  }
  .page-footer {
    position: absolute;
    bottom: 10mm;
    left: 18mm;
    right: 18mm;
    border-top: 1px solid #cbd5e1;
    padding-top: 2.5mm;
    font-size: 11pt;
    font-family: 'Times New Roman', Times, serif;
    color: #1e293b;
    letter-spacing: 0.5px;
  }
  .footer-left {
    float: left;
  }

  /* Headings */
  h1.chapter-title {
    font-size: 16pt;
    font-weight: bold;
    text-transform: uppercase;
    margin: 0 0 10pt 0;
    color: #000;
    letter-spacing: 0.5px;
  }
  h2.section-title {
    font-size: 13.5pt;
    font-weight: bold;
    text-transform: uppercase;
    margin: 12pt 0 8pt 0;
    color: #000;
  }
  h3.subsection-title {
    font-size: 12.5pt;
    font-weight: bold;
    text-transform: uppercase;
    margin: 10pt 0 6pt 0;
    color: #000;
  }
  p {
    font-size: 12pt;
    line-height: 1.42;
    text-align: justify;
    margin: 0 0 11pt 0;
    text-justify: inter-word;
  }
  ul {
    margin: 0 0 12pt 0;
    padding-left: 20pt;
  }
  li {
    font-size: 12pt;
    line-height: 1.42;
    margin-bottom: 5pt;
    text-align: justify;
  }

  /* Tables */
  table.report-table {
    width: 100%;
    border-collapse: collapse;
    margin: 8pt 0 14pt 0;
    font-size: 11pt;
    font-family: 'Times New Roman', Times, serif;
  }
  table.report-table th, table.report-table td {
    border: 1px solid #333333;
    padding: 6pt 8pt;
    vertical-align: middle;
  }
  table.report-table th {
    background: #f8fafc;
    font-weight: bold;
    text-align: left;
  }
  table.test-case-table {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 12pt;
    font-size: 10.5pt;
    font-family: 'Times New Roman', Times, serif;
  }
  table.test-case-table td {
    border: 1px solid #333333;
    padding: 4.5pt 8pt;
  }
  table.test-case-table td.tc-label {
    width: 25%;
    font-weight: bold;
  }

  /* Screenshot and Diagram Containers */
  .diagram-container {
    width: 100%;
    text-align: center;
    margin-top: 4pt;
  }
  .diagram-container img {
    max-width: 100%;
    max-height: 220mm;
    object-fit: contain;
  }
  .screenshot-container {
    width: 100%;
    text-align: center;
    margin: 6pt 0;
  }
  .screenshot-container img {
    max-width: 95%;
    max-height: 105mm;
    object-fit: contain;
    border-radius: 4px;
    box-shadow: 0 2px 6px rgba(0,0,0,0.12);
  }
  .screenshot-title {
    font-size: 13pt;
    font-weight: bold;
    text-align: center;
    margin: 4pt 0 6pt 0;
    text-decoration: underline;
  }
  .screenshot-subtitle {
    font-size: 15pt;
    font-weight: bold;
    text-align: center;
    margin: 0 0 10pt 0;
    text-decoration: underline;
    text-transform: uppercase;
  }

  @media screen {
    .page {
      margin: 20px auto;
      box-shadow: 0 0 15px rgba(0,0,0,0.5);
    }
  }
</style>
</head>
<body>
"""

HTML_PAGES = []

# =========================================================================
# PAGE 1: COVER PAGE
# =========================================================================
p1 = f"""
<div class="page">
  <div class="page-inner" style="display:flex; flex-direction:column; justify-content:space-between; text-align:center; padding: 18mm 18mm 14mm 18mm;">
    <div>
      <div style="margin-top: 5mm; margin-bottom: 4mm;">
        <img src="{logo_rku_top}" style="height: 24mm; object-fit: contain;" alt="RK University"/>
      </div>
      <div style="font-size: 24pt; font-weight: bold; margin-top: 10mm; margin-bottom: 12mm; letter-spacing: 0.5px;">
        WorkBridge &ndash; Service Marketplace
      </div>
      <div style="font-size: 11pt; line-height: 1.6; font-weight: 500; text-transform: uppercase; margin-bottom: 12mm; padding: 0 10mm;">
        A PROJECT REPORT SUBMITTED IN PARTIAL FULFILLMENT OF THE REQUIREMENT<br>
        FOR THE AWARD OF THE DEGREE OF<br>
        <b style="font-size: 12pt;">SCHOOL OF ENGINEERING RK UNIVERSITY, RAJKOT</b>
      </div>
      <div style="font-size: 13pt; font-weight: bold; text-transform: uppercase; margin-bottom: 8mm;">
        SUBMITTED BY
      </div>
      <div style="display: flex; justify-content: center; margin-bottom: 14mm;">
        <table style="width: 75%; font-size: 11.5pt; font-weight: bold; text-align: left; border-collapse: collapse;">
          <tr>
            <td style="padding: 4pt 10pt;">NAME:</td>
            <td style="padding: 4pt 10pt;">ENROLLMENT NO:</td>
          </tr>
          <tr>
            <td style="padding: 4pt 10pt; font-weight: normal;">Henil Mungapara</td>
            <td style="padding: 4pt 10pt; font-weight: normal;">25SOECA21060</td>
          </tr>
        </table>
      </div>
      <div style="font-size: 13pt; font-weight: bold; text-transform: uppercase; margin-bottom: 6mm;">
        UNDER THE GUIDANCE OF
      </div>
      <div style="display: flex; justify-content: space-around; text-align: left; padding: 0 8mm; margin-bottom: 6mm;">
        <div>
          <div style="font-size: 12pt; font-weight: bold;">Prof. Parvez Belim Sir</div>
          <div style="font-size: 10.5pt; color: #333;">Assistant Professor,<br>School of Engineering,<br>RK University<br>Rajkot.</div>
        </div>
        <div>
          <div style="font-size: 12pt; font-weight: bold;">Prof. Paresh Tanna</div>
          <div style="font-size: 10.5pt; color: #333;">HOD(Head of Department),<br>School of Engineering,<br>RK University<br>Rajkot.</div>
        </div>
      </div>
    </div>
    <div>
      <div style="margin-bottom: 2mm;">
        <img src="{logo_rku_bottom}" style="height: 22mm; object-fit: contain;" alt="School of Engineering RK University"/>
      </div>
      <div style="font-size: 11pt; font-weight: bold; text-transform: uppercase;">
        SCHOOL OF ENGINEERING, RK UNIVERSITY, RAJKOT
      </div>
    </div>
  </div>
</div>
"""
HTML_PAGES.append(p1)

# =========================================================================
# PAGE 2: DECLARATION
# =========================================================================
p2 = f"""
<div class="page">
  <div class="page-inner" style="padding-top: 15mm;">
    <div style="text-align: center; margin-bottom: 8mm;">
      <img src="{logo_rku_top}" style="height: 22mm; object-fit: contain;" alt="RK University"/>
    </div>
    <div style="text-align: center; font-size: 15pt; font-weight: bold; text-transform: uppercase; margin-bottom: 12mm; letter-spacing: 0.5px;">
      DECLARATION
    </div>
    <p style="font-size: 12pt; line-height: 1.6; text-align: justify; text-indent: 30pt; margin-bottom: 18pt;">
      I am here to certify that I am the sole author of this project work and that neither any part of this project work nor the whole of the project work has been submitted for a degree to any other University or Institution. I certify that, to the best of my knowledge, my project work does not infringe upon anyone&rsquo;s copyright nor violate any proprietary rights and that any ideas, techniques, quotations, or any other material from the work of other people included in my project document, published or otherwise, is fully acknowledged in accordance with the standard referencing practices. I declare that this is a true copy of my project work, including any final revisions, as approved by my project review committee.
    </p>
    <div style="margin-top: 25mm; font-size: 12pt;">
      <div style="font-weight: bold; margin-bottom: 8pt;">Project By</div>
      <div style="margin-bottom: 4pt; font-weight: bold;">Henil Mungapara [ 25SOECA21060 ]</div>
      <div style="margin-top: 20mm; font-weight: bold;">Date: &ndash; &nbsp; 20/04/2026</div>
    </div>
  </div>
</div>
"""
HTML_PAGES.append(p2)

# =========================================================================
# PAGE 3: TABLE OF CONTENTS (Part 1)
# =========================================================================
p3 = f"""
<div class="page">
  <div class="page-inner">
    <div style="text-align: center; font-size: 15pt; font-weight: bold; text-transform: uppercase; margin-bottom: 12pt; letter-spacing: 0.5px;">
      TABLE OF CONTENTS
    </div>
    <table class="report-table">
      <tr>
        <th style="width: 85%;">ACKNOWLEDGEMENT</th>
        <th style="width: 15%; text-align: center;"></th>
      </tr>
      <tr>
        <th>ABSTRACT</th>
        <th style="text-align: center;"></th>
      </tr>
      <tr>
        <td><b>1. INTRODUCTION</b></td>
        <td style="text-align: center;"><b>1</b></td>
      </tr>
      <tr>
        <td style="padding-left: 20pt;">1.1 PROJECT SUMMARY</td>
        <td style="text-align: center;">1</td>
      </tr>
      <tr>
        <td style="padding-left: 20pt;">1.2 PURPOSE</td>
        <td style="text-align: center;">2</td>
      </tr>
      <tr>
        <td style="padding-left: 20pt;">1.3 TECHNOLOGY: FLUTTER, DART, FIREBASE</td>
        <td style="text-align: center;">3</td>
      </tr>
      <tr>
        <td><b>2. PROJECT MANAGEMENT</b></td>
        <td style="text-align: center;"><b>4</b></td>
      </tr>
      <tr>
        <td style="padding-left: 20pt;">2.1 PROJECT PLANNING AND SCHEDULING</td>
        <td style="text-align: center;">4</td>
      </tr>
      <tr>
        <td style="padding-left: 35pt;">2.1.1 PROJECT DEVELOPMENT APPROACH</td>
        <td style="text-align: center;">5</td>
      </tr>
      <tr>
        <td style="padding-left: 35pt;">2.1.2 PROJECT PLAN</td>
        <td style="text-align: center;">6</td>
      </tr>
      <tr>
        <td style="padding-left: 35pt;">2.1.3 SCHEDULE REPRESENTATION</td>
        <td style="text-align: center;">7</td>
      </tr>
      <tr>
        <td><b>3. SYSTEM REQUIREMENTS STUDY</b></td>
        <td style="text-align: center;"><b>8</b></td>
      </tr>
      <tr>
        <td style="padding-left: 20pt;">3.1 USER CHARACTERISTICS</td>
        <td style="text-align: center;">8</td>
      </tr>
      <tr>
        <td style="padding-left: 20pt;">3.2 HARDWARE AND SOFTWARE REQUIREMENTS</td>
        <td style="text-align: center;">9</td>
      </tr>
      <tr>
        <td><b>4. SYSTEM ANALYSIS</b></td>
        <td style="text-align: center;"><b>10</b></td>
      </tr>
      <tr>
        <td style="padding-left: 20pt;">4.1 STUDY OF CURRENT SYSTEM</td>
        <td style="text-align: center;">10</td>
      </tr>
      <tr>
        <td style="padding-left: 20pt;">4.2 PROBLEM &amp; WEAKNESS OF CURRENT SYSTEM</td>
        <td style="text-align: center;">11</td>
      </tr>
      <tr>
        <td style="padding-left: 20pt;">4.3 FEASIBILITY STUDY</td>
        <td style="text-align: center;">12</td>
      </tr>
      <tr>
        <td style="padding-left: 20pt;">4.4 REQUIREMENT VALIDATION</td>
        <td style="text-align: center;">13</td>
      </tr>
      <tr>
        <td style="padding-left: 20pt;">4.5 FUNCTION SYSTEM</td>
        <td style="text-align: center;">14</td>
      </tr>
      <tr>
        <td style="padding-left: 35pt;">4.5.1 E-R DIAGRAM</td>
        <td style="text-align: center;">14</td>
      </tr>
      <tr>
        <td style="padding-left: 35pt;">4.5.2 USE CASE DIAGRAM</td>
        <td style="text-align: center;">15</td>
      </tr>
      <tr>
        <td style="padding-left: 35pt;">4.5.3 DATA FLOW DIAGRAM</td>
        <td style="text-align: center;">16</td>
      </tr>
      <tr>
        <td style="padding-left: 20pt;">4.6 DATA MODELING</td>
        <td style="text-align: center;">17</td>
      </tr>
    </table>
  </div>
</div>
"""
HTML_PAGES.append(p3)

# =========================================================================
# PAGE 4: TABLE OF CONTENTS (Part 2)
# =========================================================================
p4 = f"""
<div class="page">
  <div class="page-inner">
    <table class="report-table" style="margin-top: 10pt;">
      <tr>
        <td style="width: 85%; padding-left: 20pt;">4.7 MAIN MODULES OF NEW SYSTEM</td>
        <td style="width: 15%; text-align: center;">18</td>
      </tr>
      <tr>
        <td><b>5. SYSTEM DESIGN</b></td>
        <td style="text-align: center;"><b>19</b></td>
      </tr>
      <tr>
        <td style="padding-left: 20pt;">5.1 FLOW CHART</td>
        <td style="text-align: center;">19</td>
      </tr>
      <tr>
        <td><b>6. TESTING</b></td>
        <td style="text-align: center;"><b>20</b></td>
      </tr>
      <tr>
        <td style="padding-left: 20pt;">6.1 TEST PLAN</td>
        <td style="text-align: center;">21</td>
      </tr>
      <tr>
        <td style="padding-left: 20pt;">6.2 TESTING STRATEGY</td>
        <td style="text-align: center;">22</td>
      </tr>
      <tr>
        <td style="padding-left: 20pt;">6.3 TESTING METHODS</td>
        <td style="text-align: center;">23</td>
      </tr>
      <tr>
        <td style="padding-left: 20pt;">6.4 TESTING CASES</td>
        <td style="text-align: center;">24</td>
      </tr>
      <tr>
        <td><b>7. SCREEN SHOTS</b></td>
        <td style="text-align: center;"><b>26</b></td>
      </tr>
      <tr>
        <td><b>8. LIMITATION &amp; FUTURE ENHANCEMENT</b></td>
        <td style="text-align: center;"><b>43</b></td>
      </tr>
      <tr>
        <td><b>9. CONCLUSION AND DISCUSSION</b></td>
        <td style="text-align: center;"><b>44</b></td>
      </tr>
      <tr>
        <td><b>10 REFERENCES</b></td>
        <td style="text-align: center;"><b>45</b></td>
      </tr>
    </table>
  </div>
</div>
"""
HTML_PAGES.append(p4)

# =========================================================================
# PAGE 5: ACKNOWLEDGEMENT
# =========================================================================
p5 = f"""
<div class="page">
  <div class="page-inner" style="padding-top: 25mm;">
    <div style="text-align: center; font-size: 15pt; font-weight: bold; text-transform: uppercase; margin-bottom: 18mm; letter-spacing: 0.5px;">
      ACKNOWLEDGEMENT
    </div>
    <p style="text-indent: 25pt; line-height: 1.6; margin-bottom: 16pt;">
      The success and outcome of this project required a lot of guidance and assistance from many people, and I am extremely fortunate to have got this all along the completion of my project work. Whatever I have done is only due to such guidance and assistance and I will not forget to thank them.
    </p>
    <p style="text-indent: 25pt; line-height: 1.6; margin-bottom: 16pt;">
      I respect and thank <b>RK University</b> for giving me an opportunity to do the project work in MCA and providing me with all support and guidance which made me complete the project on time. I am extremely grateful to the university for providing such nice support and guidance.
    </p>
    <p style="text-indent: 25pt; line-height: 1.6; margin-bottom: 16pt;">
      I also thank my internal project guide, <b>Prof. Parvez Belim Sir</b>, Assistant Professor, RK University Rajkot, for his invaluable guidance, continuous support, and constructive suggestions during this project work.
    </p>
    <p style="text-indent: 25pt; line-height: 1.6; margin-bottom: 16pt;">
      I express my sincere thanks to <b>Prof. Paresh Tanna</b>, Head of Department (HOD), School of Engineering, RK University Rajkot, for his encouragement and administrative backing throughout the course of this project.
    </p>
    <p style="text-indent: 25pt; line-height: 1.6; margin-bottom: 16pt;">
      I am thankful to and fortunate enough to get constant encouragement, support and guidance from all teaching and technical staff of Department of Master of Computer Application which helped me in successfully completing my project work.
    </p>
  </div>
</div>
"""
HTML_PAGES.append(p5)

# =========================================================================
# PAGE 6: ABSTRACT
# =========================================================================
p6 = f"""
<div class="page">
  <div class="page-inner" style="padding-top: 20mm;">
    <div style="text-align: center; font-size: 15pt; font-weight: bold; text-transform: uppercase; margin-bottom: 14mm; letter-spacing: 0.5px;">
      ABSTRACT
    </div>
    <p style="text-indent: 25pt; line-height: 1.5; margin-bottom: 12pt;">
      The <b>WorkBridge</b> system is an advanced on-demand service marketplace mobile application developed using <b>Flutter</b> and <b>Firebase</b> technologies. The primary objective of this system is to simplify and modernize the home and commercial maintenance industry by connecting everyday consumers with skilled, verified local professionals (Karigars)—such as plumbers, electricians, carpenters, painters, appliance technicians, and cleaning specialists. The system reduces manual discovery effort, eliminates arbitrary middleman charges, and allows users to hire reliable technicians conveniently from anywhere.
    </p>
    <p style="text-indent: 25pt; line-height: 1.5; margin-bottom: 12pt;">
      The application provides an efficient multi-workflow platform supporting two flexible booking paradigms: broadcast dispatching (broadcasting urgent requests to all nearby verified technicians) and targeted direct hiring (booking a specific professional based on verified ratings, badges, and work history). WorkBridge incorporates live GPS tracking via OpenStreetMap to visualize technician arrival, secure multi-channel payments, and comprehensive rating reviews. Furthermore, the system introduces <b>WorkBridge Flex</b> (a recurring credit-based loyalty membership featuring a 50% carry-forward benefit upon renewal), <b>WorkBridge Share</b> (allowing members to share services with family at another address), and <b>WorkBridge Safe</b> (an interactive press-and-hold SOS safety protocol for emergency escalation).
    </p>
    <p style="text-indent: 25pt; line-height: 1.5; margin-bottom: 12pt;">
      The platform is architected around three primary user roles: <b>Customer</b>, <b>Service Provider (Karigar)</b>, and <b>Administrator</b>. Customers book and track services; professionals manage incoming gig alerts, update live transit locations, and track earnings; while administrators manage trade catalogs, verify technician KYC documentation, and oversee safety incident records through a dedicated administrative data console.
    </p>
    <p style="text-indent: 25pt; line-height: 1.5; margin-bottom: 12pt;">
      The backend is powered by <b>Google Firebase</b>, providing flexible, scalable, and reactive data storage through <b>Cloud Firestore</b> and <b>Realtime Database</b>. The frontend developed using <b>Flutter</b> ensures high-performance cross-platform execution, fluid animations, and consistent usability.
    </p>
    <p style="text-indent: 25pt; line-height: 1.5; margin-bottom: 12pt;">
      Overall, the <b>WorkBridge</b> system enhances efficiency, safety, transparency, and convenience in local service commerce, creating a sustainable digital ecosystem that empowers skilled blue-collar workers while delivering guaranteed quality to consumers.
    </p>
  </div>
</div>
"""
HTML_PAGES.append(p6)

# =========================================================================
# PAGE 7: 1 INTRODUCTION & 1.1 PROJECT SUMMARY (1 | P a g e)
# =========================================================================
p7 = f"""
<div class="page">
  <div class="page-inner">
    <h1 class="chapter-title">1 &nbsp; INTRODUCTION</h1>
    <h2 class="section-title">1.1 &nbsp; PROJECT SUMMARY</h2>
    <p style="text-indent: 25pt;">
      <b>WorkBridge</b> is a cross-platform, on-demand service marketplace application designed to modernize and bridge the divide between domestic households and skilled local technicians (Karigars). In contemporary urban and semi-urban communities, finding dependable, certified, and fairly priced technicians for urgent household tasks—such as burst water pipes, electrical short circuits, furniture damage, or appliance breakdowns—remains a frustrating, disorganized, and time-consuming chore. WorkBridge resolves this systemic market failure by delivering a centralized, reliable digital platform where customers can browse service categories, evaluate technician profiles, book on-demand repairs, make cashless payments, and track execution in real time.
    </p>
    <p style="text-indent: 25pt;">
      The mobile system is constructed using Google&rsquo;s <b>Flutter</b> framework with the <b>Dart</b> programming language, delivering high-speed native UI rendering across Android and iOS platforms from a single clean codebase. The backend is powered by <b>Google Firebase</b>, integrating <b>Cloud Firestore</b> for flexible NoSQL document management, <b>Firebase Authentication</b> for secure role-based identity validation, <b>Firebase Realtime Database</b> for low-latency GPS tracking synchronization, and <b>Cloud Messaging</b> for instant push dispatch alerts.
    </p>
    <p style="text-indent: 25pt;">
      WorkBridge incorporates industry-leading specialized features designed for real-world reliability. It offers dual dispatch modes: <i>Broadcast Requests</i> (alerting all nearby certified Karigars for rapid emergency dispatch) and <i>Specific Karigar Selection</i> (allowing direct booking of preferred professionals). To safeguard consumers during in-home technician visits, the platform incorporates <b>WorkBridge Safe</b>, a dedicated emergency safety mechanism featuring an interactive press-and-hold SOS alert that connects to emergency response, alerts trusted family contacts, and provides live technician location context.
    </p>
    <p style="text-indent: 25pt;">
      Additionally, the system introduces <b>WorkBridge Flex</b>, a customer loyalty membership offering recurring service credits with an innovative 50% renewal carry-forward policy, as well as <b>WorkBridge Share</b> to extend service credits to relatives living at different addresses. Administrative operations are governed through an integrated <b>Admin Data Hub</b> that provides end-to-end control over customer accounts, technician KYC verification, trade categories, pricing, and financial analytics.
    </p>
    <div class="page-footer"><span class="footer-left">1 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p7)

# =========================================================================
# PAGE 8: 1.2 PURPOSE (2 | P a g e)
# =========================================================================
p8 = f"""
<div class="page">
  <div class="page-inner">
    <h2 class="section-title" style="margin-top: 0;">1.2 &nbsp; PURPOSE</h2>
    <p style="text-indent: 25pt;">
      The purpose of <b>WorkBridge</b> is to provide a reliable, efficient, and transparent digital marketplace that revolutionizes how home and local services are discovered, booked, and executed. The traditional service ecosystem suffers from extreme fragmentation, arbitrary pricing, unverified worker backgrounds, and erratic scheduling. WorkBridge modernizes this unorganized sector by providing an intuitive mobile platform that connects consumers with vetted, background-verified professionals in minutes.
    </p>
    <p style="text-indent: 25pt;">
      The system enables service providers (Karigars) to build a credible digital identity, break free from exploitative local contractor cartels, receive steady direct job requests, and earn higher, predictable incomes. At the same time, platform administrators can monitor service quality, verify professional credentials, manage trade catalogs, and maintain high standards of trust, accountability, and customer satisfaction across the ecosystem.
    </p>
    <p style="margin-bottom: 6pt;"><b>This project is designed to:</b></p>
    <ul>
      <li>Reduce manual effort and delays by automating technician discovery, booking dispatch, and fulfillment tracking.</li>
      <li>Provide a smooth, responsive, and user-friendly mobile interface for exploring on-demand trade categories.</li>
      <li>Enable real-time geolocation tracking using interactive maps to display technician arrival and travel progress.</li>
      <li>Guarantee price transparency with upfront standardized estimates, cashless online payments (Razorpay), cash on delivery, and membership credit options.</li>
      <li>Empower skilled blue-collar professionals with dignified digital profiles, ratings, and instant job allocation.</li>
      <li>Protect user safety during active in-home service visits through the integrated WorkBridge Safe emergency SOS protocol.</li>
      <li>Foster customer retention and repeat usage through WorkBridge Flex membership credits and family service sharing.</li>
      <li>Provide administrators with robust oversight tools for technician KYC document verification, catalog management, and audit reporting.</li>
    </ul>
    <p style="text-indent: 25pt;">
      Overall, the purpose of this project is to deliver a secure, scalable, and equitable service ecosystem that uplifts local artisans while giving homeowners dependable, fast, and high-quality maintenance services.
    </p>
    <div class="page-footer"><span class="footer-left">2 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p8)

# =========================================================================
# PAGE 9: 1.3 TECHNOLOGY: FLUTTER, DART, FIREBASE (3 | P a g e)
# =========================================================================
p9 = f"""
<div class="page">
  <div class="page-inner">
    <h2 class="section-title" style="margin-top: 0;">1.3 &nbsp; TECHNOLOGY: FLUTTER, DART, FIREBASE</h2>
    <p style="text-indent: 25pt;">
      The development of <b>WorkBridge</b> is grounded in modern cross-platform mobile architecture and reactive cloud services. <b>Flutter</b>, Google&rsquo;s open-source UI software development kit, serves as the primary frontend framework. Flutter enables the development of natively compiled, high-performance applications for Android and iOS from a single Dart codebase. It provides smooth 60fps animations, rich material design widgets, responsive layouts, and rapid development capabilities.
    </p>
    <p style="text-indent: 25pt;">
      <b>Dart</b> is the core object-oriented programming language powering the application logic. Dart offers strong typing, sound null-safety, and asynchronous event loops (Futures and Streams) that are vital for real-time mobile tasks such as continuous GPS location listening, Firestore stream subscriptions, and network request handling. State management across the application is engineered using the <b>Provider</b> pattern, ensuring predictable data flow, reactive widget rebuilding, and separation of UI components from business logic.
    </p>
    <p style="text-indent: 25pt;">
      <b>Google Firebase</b> serves as the scalable serverless backend platform for WorkBridge. <b>Cloud Firestore</b>, a high-performance NoSQL document database, stores and synchronizes domain collections including users, service categories, booking requests, ratings, and payment logs. Firestore&rsquo;s real-time listeners enable instant UI synchronization across client devices. <b>Firebase Authentication</b> handles secure user identity validation with email/password and phone OTP support, while <b>Firebase Realtime Database</b> provides ultra-low latency coordinate streaming for live technician map tracking.
    </p>
    <p style="text-indent: 25pt;">
      Mapping and location services are implemented using the <b>Geolocator</b> and <b>Flutter Map</b> (OpenStreetMap / Leaflet) packages, allowing precise GPS position acquisition, address reverse geocoding, and interactive route visualization without incurring prohibitive commercial map licensing costs.
    </p>
    <p style="text-indent: 25pt;">
      Overall, <b>Flutter, Dart, and Firebase</b> form an exceptionally robust, modern, and scalable technology stack that ensures WorkBridge delivers high responsiveness, cross-platform compatibility, and resilient real-time cloud data handling.
    </p>
    <div class="page-footer"><span class="footer-left">3 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p9)

# =========================================================================
# PAGE 10: 2 PROJECT MANAGEMENT & 2.1 PROJECT PLANNING AND SCHEDULING (4 | P a g e)
# =========================================================================
p10 = f"""
<div class="page">
  <div class="page-inner">
    <h1 class="chapter-title">2 &nbsp; PROJECT MANAGEMENT</h1>
    <h2 class="section-title">2.1 &nbsp; PROJECT PLANNING AND SCHEDULING</h2>
    <p style="text-indent: 25pt;">
      Project planning and scheduling for <b>WorkBridge</b> were structured to ensure disciplined execution, technical rigor, and timely delivery of an enterprise-grade mobile platform. Because WorkBridge involves a complex, three-sided marketplace—encompassing homeowners, skilled blue-collar workers, and platform administrators—the project scope was divided into distinct, manageable phases with clearly defined milestones, deliverables, and quality criteria.
    </p>
    <p style="text-indent: 25pt;">
      The <b>Planning Phase</b> began with exhaustive requirement elicitation and field domain research. This involved analyzing traditional home maintenance pain points, technician availability challenges, pricing opacity, and safety risks during in-home visits. Functional specifications were established for core system modules, including multi-role authentication, trade category catalogs, dual booking dispatch algorithms (broadcast vs specific hiring), live map tracking, payment reconciliation, and safety escalation channels.
    </p>
    <p style="text-indent: 25pt;">
      The <b>Design Phase</b> focused on creating the system architecture, component hierarchies, wireframe prototypes, and the Cloud Firestore NoSQL schema. Security rules and role access boundaries were drafted to ensure complete data isolation between customer and provider accounts. During the <b>Development Phase</b>, modular programming was conducted in Flutter and Dart, implementing state providers, repository layers, and reactive Firebase cloud services.
    </p>
    <p style="text-indent: 25pt;">
      <b>Scheduling</b> was allocated across sequential two-week sprint intervals covering frontend design, backend integration, geolocation testing, bug fixing, and optimization. Continuous validation helped identify edge cases early—such as GPS signal drops or offline provider status—ensuring system stability before final academic submission.
    </p>
    <p style="text-indent: 25pt;">
      Proper planning and disciplined scheduling enabled the successful completion of the WorkBridge platform within the stipulated university timeframe, resulting in a cohesive, reliable, and thoroughly verified software solution.
    </p>
    <div class="page-footer"><span class="footer-left">4 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p10)

# =========================================================================
# PAGE 11: 2.1.1 PROJECT DEVELOPMENT APPROACH (5 | P a g e)
# =========================================================================
p11 = f"""
<div class="page">
  <div class="page-inner">
    <h3 class="subsection-title" style="margin-top: 0;">2.1.1 &nbsp; PROJECT DEVELOPMENT APPROACH</h3>
    <p style="text-indent: 25pt;">
      The engineering of <b>WorkBridge</b> followed an <b>Agile Iterative Development Approach</b> tailored for modern on-demand service platforms. The project was executed through iterative cycles comprising requirement refinement, architectural modeling, rapid prototyping, feature implementation, and rigorous cross-platform testing. This methodology provided the flexibility needed to evolve system behavior based on practical testing feedback while maintaining structural clarity.
    </p>
    <p style="text-indent: 25pt;">
      In the initial iteration, foundational requirements were prioritized, establishing user data models (Customer, Provider, Admin) and implementing multi-role authentication via Firebase Auth. Once identity validation was proven stable, subsequent iterations focused on the customer experience—building service category browsers, technician profile viewers, and booking request dispatchers.
    </p>
    <p style="text-indent: 25pt;">
      The third iteration concentrated on the provider and tracking subsystems. Real-time background listeners were integrated to alert technicians of incoming jobs, while the <b>Geolocator</b> and <b>Flutter Map</b> engines were connected to stream live coordinates between moving technicians and the customer&rsquo;s tracking view. A concurrent iteration implemented the administrative data console, enabling supervisors to verify technician credentials, inspect active bookings, and moderate reviews.
    </p>
    <p style="text-indent: 25pt;">
      In the final iterations, proprietary specialized mechanisms were integrated and verified: <b>WorkBridge Safe</b> (the press-and-hold SOS safety protocol) and <b>WorkBridge Flex</b> (the credit-based loyalty subscription with 50% rollover rules). Automated unit tests, widget tests, and simulated field runs were executed at every stage to detect and eliminate race conditions or validation flaws.
    </p>
    <p style="text-indent: 25pt;">
      This structured development approach ensured that the WorkBridge platform is highly maintainable, resilient under variable network conditions, and capable of satisfying real-world commercial and academic requirements effectively.
    </p>
    <div class="page-footer"><span class="footer-left">5 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p11)

# =========================================================================
# PAGE 12: 2.1.2 PROJECT PLAN (6 | P a g e)
# =========================================================================
p12 = f"""
<div class="page">
  <div class="page-inner">
    <h3 class="subsection-title" style="margin-top: 0;">2.1.2 &nbsp; PROJECT PLAN</h3>
    <p style="text-indent: 25pt;">
      The project plan for <b>WorkBridge</b> defines the systematic breakdown of tasks, resource distributions, and logical activity sequences required to complete the platform within the allocated academic schedule. Tasks were structured to avoid implementation bottlenecks and guarantee smooth transitions between architectural design, coding, integration, and verification.
    </p>
    <p style="margin-bottom: 6pt;"><b>The project plan incorporates the following seven primary activities:</b></p>
    <p style="margin-bottom: 6pt;"><b>1. Requirement Collection and Analysis</b><br>
    Conducting market analysis of local home services, interviewing consumers and trade professionals, identifying workflow requirements, and establishing formal software requirement specifications (SRS) for customer, provider, and admin roles.</p>
    <p style="margin-bottom: 6pt;"><b>2. System Architecture and UI/UX Design</b><br>
    Designing application navigational wireframes, high-fidelity Flutter widget hierarchies, Cloud Firestore database schemas, security rules, and formal UML/DFD design diagrams.</p>
    <p style="margin-bottom: 6pt;"><b>3. Mobile Frontend Development</b><br>
    Coding the customer and provider interfaces in Flutter, including splash, onboarding, category grids, service request modals, provider dashboards, and profile management screens.</p>
    <p style="margin-bottom: 6pt;"><b>4. Cloud Backend &amp; Firebase Integration</b><br>
    Integrating Firebase Authentication, Cloud Firestore real-time streams, Cloud Messaging push alerts, and backend repository controllers for booking lifecycles and payment processing.</p>
    <p style="margin-bottom: 6pt;"><b>5. Geolocation Engine &amp; Live Tracking</b><br>
    Implementing Geolocator GPS tracking, OpenStreetMap tile rendering, dynamic route calculation, and real-time technician-to-customer coordinate streaming.</p>
    <p style="margin-bottom: 6pt;"><b>6. Quality Assurance, Testing and Debugging</b><br>
    Conducting black-box functional testing, white-box logic validation, integration verification across cloud services, edge-case simulation, and performance profiling.</p>
    <p style="margin-bottom: 6pt;"><b>7. Documentation and Academic Submission</b><br>
    Authoring the comprehensive project report, capturing screen documentation, validating UML diagrams, and compiling project deliverables for formal degree evaluation.</p>
    <div class="page-footer"><span class="footer-left">6 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p12)

# =========================================================================
# PAGE 13: 2.1.3 SCHEDULE REPRESENTATION (7 | P a g e)
# =========================================================================
p13 = f"""
<div class="page">
  <div class="page-inner">
    <h3 class="subsection-title" style="margin-top: 0;">2.1.3 &nbsp; Schedule Representation</h3>
    <p style="text-indent: 25pt;">
      The schedule representation of the <b>WorkBridge</b> project defines the project timeline, milestones, and chronological workflow required for successful software deployment. It establishes an organized roadmap that enabled systematic task tracking, efficient dependency management, and timely delivery of complex multi-stakeholder features.
    </p>
    <p style="text-indent: 25pt;">
      In the WorkBridge project, the schedule was divided into sequential development milestones spanning requirement analysis, UI prototyping, core Flutter coding, cloud backend integration, specialized feature development (WorkBridge Flex &amp; Safe), and comprehensive system testing. Each phase was assigned specific durations based on technical complexity and risk factors.
    </p>
    <table class="report-table" style="font-size: 10pt; margin: 10pt 0 14pt 0;">
      <tr style="background: #f1f5f9;">
        <th style="width: 25%;">Phase / Activity</th>
        <th style="width: 35%;">Key Deliverables</th>
        <th style="width: 20%;">Allocated Time</th>
        <th style="width: 20%;">Status</th>
      </tr>
      <tr>
        <td><b>Phase 1: Requirement Analysis</b></td>
        <td>SRS Document, Use Cases &amp; Market Research</td>
        <td>Week 1 &ndash; Week 2</td>
        <td>Completed</td>
      </tr>
      <tr>
        <td><b>Phase 2: UI/UX &amp; Architecture</b></td>
        <td>Figma Mockups, Schema Design &amp; UML</td>
        <td>Week 3 &ndash; Week 4</td>
        <td>Completed</td>
      </tr>
      <tr>
        <td><b>Phase 3: Core App Development</b></td>
        <td>Flutter UI Views, State Providers &amp; Auth</td>
        <td>Week 5 &ndash; Week 8</td>
        <td>Completed</td>
      </tr>
      <tr>
        <td><b>Phase 4: Cloud &amp; Location Engine</b></td>
        <td>Firestore Sync, Live GPS Map &amp; Push Alerts</td>
        <td>Week 9 &ndash; Week 11</td>
        <td>Completed</td>
      </tr>
      <tr>
        <td><b>Phase 5: Flex, Safe &amp; Admin</b></td>
        <td>WorkBridge Flex, SOS Protocol &amp; Admin Hub</td>
        <td>Week 12 &ndash; Week 13</td>
        <td>Completed</td>
      </tr>
      <tr>
        <td><b>Phase 6: Testing &amp; Final Report</b></td>
        <td>Test Cases, UAT, Documentation &amp; PDF</td>
        <td>Week 14 &ndash; Week 16</td>
        <td>Completed</td>
      </tr>
    </table>
    <p style="text-indent: 25pt;">
      By strictly adhering to this schedule representation, the development of the WorkBridge system proceeded in an orderly and predictable manner, ensuring high architectural quality and on-time academic project delivery.
    </p>
    <div class="page-footer"><span class="footer-left">7 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p13)

# =========================================================================
# PAGE 14: 3.1 SYSTEM REQUIREMENTS STUDY & 3.1 USER CHARACTERISTICS (8 | P a g e)
# =========================================================================
p14 = f"""
<div class="page">
  <div class="page-inner">
    <h1 class="chapter-title">3 &nbsp; SYSTEM REQUIREMENTS STUDY</h1>
    <h2 class="section-title">3.1 &nbsp; USER CHARACTERISTICS</h2>
    <p style="text-indent: 25pt;">
      The <b>WorkBridge</b> marketplace is designed to accommodate three distinct user classes: <b>Customers (Homeowners)</b>, <b>Service Providers (Karigars / Professionals)</b>, and the <b>Platform Administrator</b>. Each user group exhibits unique operational responsibilities, technical literacy levels, and system access permissions.
    </p>
    <p style="margin-bottom: 4pt;"><b>1. Customers (Homeowners / Clients):</b></p>
    <p style="text-indent: 25pt;">
      Customers are general domestic consumers who use the application to discover, schedule, and pay for household maintenance services. They possess standard familiarity with consumer mobile apps and smartphones. Customers can register, verify identity via OTP, browse trade catalogs (Plumbing, Electrical, Carpentry, etc.), filter technicians, select dispatch methods (Broadcast or Specific), track technician arrival via live GPS map, execute payments, manage WorkBridge Flex credits, trigger emergency SOS alerts via WorkBridge Safe, and submit star ratings and textual reviews. No technical expertise is required; the UI is designed to be self-explanatory, clean, and accessible.
    </p>
    <p style="margin-bottom: 4pt;"><b>2. Service Providers (Karigars / Skilled Professionals):</b></p>
    <p style="text-indent: 25pt;">
      Service Providers are skilled blue-collar artisans and technicians. They may possess basic or moderate digital literacy. WorkBridge provides an ultra-streamlined, high-contrast interface designed for quick one-tap actions. Providers can register, upload KYC identity documents for verification, manage trade specializations, review incoming job request cards, accept or decline gigs within a timeout countdown, update live transit locations, change execution states (Arrived, In-Progress, Completed), view accrued daily/weekly earnings, and inspect customer feedback ratings.
    </p>
    <p style="margin-bottom: 4pt;"><b>3. System Administrator:</b></p>
    <p style="text-indent: 25pt;">
      The administrator is a high-privilege technical supervisor responsible for overall platform governance. The admin manages customer and provider records, audits submitted KYC documents to approve or suspend Karigars, maintains the service category catalog, monitors real-time active bookings, reviews emergency incident logs generated by WorkBridge Safe, audits platform commission payouts, and analyzes operational revenue reports.
    </p>
    <div class="page-footer"><span class="footer-left">8 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p14)

# =========================================================================
# PAGE 15: 3.2 HARDWARE AND SOFTWARE REQUIREMENTS (9 | P a g e)
# =========================================================================
p15 = f"""
<div class="page">
  <div class="page-inner">
    <h2 class="section-title" style="margin-top: 0;">3.2 &nbsp; HARDWARE AND SOFTWARE REQUIREMENTS</h2>
    <p style="text-indent: 25pt;">
      The <b>WorkBridge</b> system requires specific hardware and software components to ensure smooth development, cross-platform compilation, database scalability, and reliable end-user mobile execution.
    </p>
    <p style="margin-bottom: 4pt;"><b>Hardware Requirements:</b></p>
    <p style="margin-bottom: 3pt;">The hardware requirements define the physical workstations and testing devices utilized to build and operate WorkBridge efficiently.</p>
    <ul>
      <li><b>Processor:</b> Intel Core i5 / i7 or AMD Ryzen 5 / 7 (Multi-core, 2.5 GHz or higher).</li>
      <li><b>RAM:</b> Minimum 8 GB (16 GB strongly recommended for smooth Android Studio emulator execution).</li>
      <li><b>Storage:</b> Minimum 20 GB free disk space (Solid State Drive SSD recommended for fast Flutter builds).</li>
      <li><b>Development Workstation:</b> Laptop or Desktop PC running modern 64-bit OS.</li>
      <li><b>Mobile Testing Devices:</b> Physical Android smartphone (Android OS 9.0 Pie or higher, GPS and internet enabled) and/or iOS device (iOS 13.0+).</li>
      <li><b>Network Connection:</b> High-speed broadband / 4G / 5G internet for real-time Firebase cloud sync and map tile streaming.</li>
    </ul>
    <p style="margin-bottom: 4pt;"><b>Software Requirements:</b></p>
    <p style="margin-bottom: 3pt;">The software requirements encompass the developer toolchains, frameworks, cloud infrastructure, and libraries powering the application.</p>
    <ul>
      <li><b>Operating System:</b> Windows 10/11 (64-bit), macOS, or Linux.</li>
      <li><b>Development IDE:</b> Visual Studio Code and/or Android Studio with Flutter &amp; Dart plugins.</li>
      <li><b>SDK:</b> Flutter SDK (v3.24+ / 3.9.2), Dart SDK (v3.5+).</li>
      <li><b>State Management:</b> Provider Package (v6.1.2) for reactive architectural state separation.</li>
      <li><b>Cloud Backend:</b> Google Firebase (Firebase Core, Firebase Auth, Cloud Firestore, Realtime Database, Cloud Messaging, Cloud Storage).</li>
      <li><b>Mapping &amp; GPS:</b> Geolocator (v14.0+), Latlong2, and Flutter Map (v8.3+) utilizing OpenStreetMap tiles.</li>
      <li><b>Payment Processing:</b> Razorpay Gateway SDK / Integration utilities.</li>
      <li><b>Version Control:</b> Git and GitHub for collaborative source control and tracking.</li>
    </ul>
    <div class="page-footer"><span class="footer-left">9 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p15)

# =========================================================================
# PAGE 16: 4 SYSTEM ANALYSIS & 4.1 STUDY OF CURRENT SYSTEM (10 | P a g e)
# =========================================================================
p16 = f"""
<div class="page">
  <div class="page-inner">
    <h1 class="chapter-title">4 &nbsp; SYSTEM ANALYSIS</h1>
    <h2 class="section-title">4.1 &nbsp; STUDY OF CURRENT SYSTEM</h2>
    <p style="text-indent: 25pt;">
      In the conventional home services market, finding skilled labor—such as a licensed plumber, certified electrician, carpenter, or appliance repair technician—relies heavily on informal, word-of-mouth recommendations, neighborhood hardware store inquiries, or unverified phone directories. This traditional approach is plagued by severe friction, unpredictability, and total lack of standardization.
    </p>
    <p style="text-indent: 25pt;">
      When an emergency household fault occurs—such as a ruptured water pipe or electrical short-circuit—homeowners are forced to make numerous phone calls to independent technicians whose current availability, geographical distance, and pricing rates are completely unknown. In many cases, technicians do not answer, arrive hours late, or fail to show up altogether. Furthermore, because pricing is negotiated informally without standard rate cards, consumers are routinely subjected to arbitrary overcharging, unexpected hidden fees, and inflated replacement parts costs.
    </p>
    <p style="text-indent: 25pt;">
      Safety and background verification represent another critical vulnerability in the existing system. Allowing unverified, anonymous workers into private residential spaces poses substantial security risks for homeowners, particularly women, children, and elderly individuals. Traditional methods provide zero background checks, no government ID verification, and no recourse or institutional accountability if shoddy work causes structural property damage.
    </p>
    <p style="text-indent: 25pt;">
      Conversely, skilled technicians (Karigars) also suffer under the traditional model. They lack dependable marketing channels and are frequently exploited by local contractors who take large cuts of their earnings. Technicians endure irregular gig flow, delayed cash payments, and have no platform to accumulate a verified professional reputation.
    </p>
    <p style="text-indent: 25pt;">
      These profound limitations underscore the urgent necessity for a modern, digital on-demand solution. <b>WorkBridge</b> addresses these systemic failures by delivering a structured, mobile-first marketplace that brings transparency, instant dispatch, verified accountability, and automated safety to domestic maintenance commerce.
    </p>
    <div class="page-footer"><span class="footer-left">10 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p16)

# =========================================================================
# PAGE 17: 4.2 PROBLEM AND WEAKNESSES OF CURRENT SYSTEM (11 | P a g e)
# =========================================================================
p17 = f"""
<div class="page">
  <div class="page-inner">
    <h2 class="section-title" style="margin-top: 0;">4.2 &nbsp; PROBLEM AND WEAKNESSES OF CURRENT SYSTEM</h2>
    <p style="text-indent: 25pt;">
      A comprehensive analysis of the existing informal local service ecosystem reveals deep-seated operational, financial, and security problems across all participant groups:
    </p>
    <p style="margin-bottom: 3pt;"><b>For Customers (Homeowners):</b></p>
    <ul>
      <li>High search friction and lost time attempting to locate nearby available technicians.</li>
      <li>Unpredictable response times with frequent no-shows during urgent emergencies.</li>
      <li>Opaque and arbitrary pricing with no standardized upfront rate cards or digital receipts.</li>
      <li>Significant safety and security concerns regarding unverified workers inside private homes.</li>
      <li>Zero recourse, warranty, or formal dispute escalation if services are executed improperly.</li>
      <li>Absence of digital service history, itemized billing, or loyalty benefits.</li>
    </ul>
    <p style="margin-bottom: 3pt;"><b>For Service Providers (Karigars / Technicians):</b></p>
    <ul>
      <li>Erratic, unpredictable work pipelines resulting in substantial income instability.</li>
      <li>Heavy dependency on predatory local contractors and middlemen who extract exorbitant commissions.</li>
      <li>Delayed cash payments and disputes over agreed-upon labor fees.</li>
      <li>Inability to showcase verified craftsmanship, skills, certifications, and customer reviews.</li>
      <li>Inefficient travel across distant neighborhoods due to lack of localized routing tools.</li>
    </ul>
    <p style="margin-bottom: 3pt;"><b>System-Level Weaknesses:</b></p>
    <ul>
      <li>Total absence of a centralized digital directory of authenticated, KYC-verified trade professionals.</li>
      <li>No real-time GPS tracking or route visualization for technician transit.</li>
      <li>Complete lack of emergency safety mechanisms during active residential service calls.</li>
      <li>Inability to generate macroeconomic labor analytics, tax audit trails, or industry trend metrics.</li>
      <li>High market fragmentation preventing scalability and service quality standardization.</li>
    </ul>
    <div class="page-footer"><span class="footer-left">11 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p17)

# =========================================================================
# PAGE 18: 4.3 FEASIBILITY STUDY (12 | P a g e)
# =========================================================================
p18 = f"""
<div class="page">
  <div class="page-inner">
    <h2 class="section-title" style="margin-top: 0;">4.3 &nbsp; FEASIBILITY STUDY</h2>
    <p style="text-indent: 25pt;">
      The feasibility study for the <b>WorkBridge</b> system evaluates the practical viability, technical capability, financial sustainability, and operational readiness of the platform.
    </p>
    <p style="margin-bottom: 3pt;"><b>1. Technical Feasibility</b></p>
    <p style="text-indent: 25pt;">
      WorkBridge is technically feasible as it leverages Google&rsquo;s established <b>Flutter</b> UI framework and <b>Firebase</b> cloud backend. These open-source and serverless technologies are widely adopted, fully documented, and engineered for high concurrency. Flutter delivers compile-time native speed across Android and iOS, while Cloud Firestore and Realtime Database provide horizontal cloud scalability. Geolocation tracking is accomplished efficiently using open-source OpenStreetMap tiles and the device GPS, avoiding restrictive third-party API dependencies.
    </p>
    <p style="margin-bottom: 3pt;"><b>2. Operational Feasibility</b></p>
    <p style="text-indent: 25pt;">
      The platform is operationally feasible because it is specifically tailored to the real-world behaviors of its users. Customers interact with a modern, consumer-grade shopping interface with minimal onboarding barriers. For Karigars, the interface utilizes bold icons, audio-visual job alerts, and one-tap accept/reject mechanisms that accommodate varying levels of digital literacy. Administrators gain a centralized dashboard that automates verification, dispatch, and safety oversight without requiring extensive staff.
    </p>
    <p style="margin-bottom: 3pt;"><b>3. Economic Feasibility</b></p>
    <p style="text-indent: 25pt;">
      The development of WorkBridge is cost-effective because it utilizes open-source development tools (VS Code, Flutter SDK, Dart) and Firebase&rsquo;s free/low-cost development tier. In production, the system generates diversified revenues through a sustainable two-sided business model: service commissions from completed gigs, recurring WorkBridge Flex memberships, optional featured listings for top Karigars, and platform convenience fees.
    </p>
    <p style="margin-bottom: 3pt;"><b>4. Schedule Feasibility</b></p>
    <p style="text-indent: 25pt;">
      By organizing tasks into six disciplined agile phases and leveraging Flutter&rsquo;s rapid widget prototyping, all design, development, testing, and documentation activities were completed strictly within university academic milestone deadlines.
    </p>
    <div class="page-footer"><span class="footer-left">12 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p18)

# =========================================================================
# PAGE 19: 4.4 REQUIREMENTS VALIDATION (13 | P a g e)
# =========================================================================
p19 = f"""
<div class="page">
  <div class="page-inner">
    <h2 class="section-title" style="margin-top: 0;">4.4 &nbsp; REQUIREMENTS VALIDATION</h2>
    <p style="text-indent: 25pt;">
      The Requirements Validation process for <b>WorkBridge</b> ensures that all identified functional and non-functional requirements are technically accurate, mutually consistent, and fully aligned with the expectations of customers, technicians, and administrators. This validation guarantees that the software addresses real-world operational challenges rather than hypothetical assumptions.
    </p>
    <p style="text-indent: 25pt;">
      In the WorkBridge project, requirements were validated through systematic reviews of real user workflows:
    </p>
    <ul>
      <li><b>Role Authentication &amp; Permissions:</b> Ensuring strict isolation between Customer, Service Provider, and Admin accounts so that providers cannot access customer booking creation APIs and customers cannot accept gig requests.</li>
      <li><b>Dual Dispatch Engine Validation:</b> Validating that <i>Broadcast Requests</i> properly fan out to all active technicians registered under the chosen trade category within a geographic radius, while <i>Specific Karigar Requests</i> route exclusively to the targeted professional.</li>
      <li><b>Geolocation &amp; Real-Time Tracking:</b> Verifying that technician GPS updates synchronize reliably to Cloud Firestore and Realtime Database, calculating accurate ETAs and visualizing route paths on OpenStreetMap without excessive battery drain.</li>
      <li><b>WorkBridge Safe Emergency Response:</b> Thoroughly verifying that the press-and-hold SOS button cannot be triggered accidentally, automatically dials emergency services, pushes SMS/notifications with coordinates to trusted contacts, and flags active incidents on the Admin Console.</li>
      <li><b>WorkBridge Flex Ledger Integrity:</b> Verifying credit allocation (10/month), usage deduction upon service completion, and proper calculation of the 50% rollover rule at membership renewal.</li>
      <li><b>Payment Reconciliation:</b> Testing Razorpay webhook callbacks to ensure transaction status matches booking state transitions.</li>
    </ul>
    <p style="text-indent: 25pt;">
      Overall, the validation process confirmed that WorkBridge is functionally comprehensive, secure, and fully prepared for reliable live implementation.
    </p>
    <div class="page-footer"><span class="footer-left">13 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p19)

# =========================================================================
# PAGE 20: 4.5 FUNCTIONS OF SYSTEM & 4.5.1 ER Diagram (14 | P a g e)
# =========================================================================
p20 = f"""
<div class="page">
  <div class="page-inner" style="padding-top: 12mm;">
    <h1 class="chapter-title" style="margin-bottom: 4pt;">4.5 &nbsp; FUNCTIONS OF SYSTEM</h1>
    <h2 class="section-title" style="margin-top: 0; margin-bottom: 6pt;">4.5.1 &nbsp; ER Diagram</h2>
    <p style="font-size: 10.5pt; line-height: 1.35; margin-bottom: 6pt;">
      The Entity-Relationship (ER) diagram models the logical schema of the WorkBridge marketplace. It defines the core domain entities—Users, Categories, Service Requests, Payments, Reviews, Flex Memberships, Safety Incidents, and Locations—along with their primary keys (PK), foreign keys (FK), and cardinality relationships.
    </p>
    <div class="diagram-container">
      <img src="{diag_er}" style="max-height: 205mm;" alt="WorkBridge ER Diagram"/>
    </div>
    <div class="page-footer"><span class="footer-left">14 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p20)

# =========================================================================
# PAGE 21: 4.5.2 User Case Diagram (15 | P a g e)
# =========================================================================
p21 = f"""
<div class="page">
  <div class="page-inner" style="padding-top: 12mm;">
    <h2 class="section-title" style="margin-top: 0; margin-bottom: 6pt;">4.5.2 &nbsp; User Case Diagram</h2>
    <p style="font-size: 10.5pt; line-height: 1.35; margin-bottom: 6pt;">
      The Use Case diagram illustrates the behavioral interactions between the system actors (Customer, Service Provider/Karigar, and Administrator) and the platform use cases, detailing &laquo;include&raquo; and &laquo;extend&raquo; relationships.
    </p>
    <div class="diagram-container">
      <img src="{diag_usecase}" style="max-height: 210mm;" alt="WorkBridge Use Case Diagram"/>
    </div>
    <div class="page-footer"><span class="footer-left">15 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p21)

# =========================================================================
# PAGE 22: 4.5.3 Data Flow Diagram (0 and 1 level) (16 | P a g e)
# =========================================================================
p22 = f"""
<div class="page">
  <div class="page-inner" style="padding-top: 12mm;">
    <h2 class="section-title" style="margin-top: 0; margin-bottom: 6pt;">4.5.3 &nbsp; Data Flow Diagram (0 and 1 level)</h2>
    <p style="font-size: 10.5pt; line-height: 1.35; margin-bottom: 6pt;">
      The Data Flow Diagram illustrates the logical flow of information through the WorkBridge architecture, detailing both the high-level Level 0 Context Diagram and the decomposed Level 1 process and data store interactions.
    </p>
    <div class="diagram-container">
      <img src="{diag_dfd}" style="max-height: 210mm;" alt="WorkBridge Data Flow Diagram (Level 0 and Level 1)"/>
    </div>
    <div class="page-footer"><span class="footer-left">16 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p22)

# =========================================================================
# PAGE 23: 4.6 DATA MODELING (17 | P a g e)
# =========================================================================
p23 = f"""
<div class="page">
  <div class="page-inner">
    <h2 class="section-title" style="margin-top: 0;">4.6 &nbsp; DATA MODELING</h2>
    <p style="text-indent: 25pt;">
      Data modeling for the <b>WorkBridge</b> system defines how application entities, business transactions, and real-time states are structured and stored within <b>Cloud Firestore</b>, a scalable NoSQL cloud document database. Documents are organized into modular collections, supporting rapid reactive streaming and atomic data operations.
    </p>
    <p style="margin-bottom: 4pt;"><b>The primary collections used in the WorkBridge system are:</b></p>
    <ul>
      <li><b>users:</b> Stores unified user identity records including UID, full name, email, phone number, hashed password, canonical system role (<code>customer</code>, <code>service_provider</code>, <code>admin</code>), verification badge status (<code>isVerified</code>), assigned trade categories, and creation timestamps.</li>
      <li><b>service_categories:</b> Defines the 8 canonical service trade categories (Plumbing, Electrical, Carpentry, Painting, Cleaning, Appliance Repair, Salon &amp; Beauty, Vehicle Services) with icon identifiers, accent colors, active status, and provider counts.</li>
      <li><b>service_requests:</b> Manages service bookings, capturing customer ID, category ID, title, description, estimated price, scheduled date and time, dispatch type (<code>broadcast</code> vs <code>specific</code>), target provider ID, assigned provider ID, execution status (<code>pending</code>, <code>accepted</code>, <code>in_progress</code>, <code>completed</code>, <code>cancelled</code>), and customer GPS coordinates.</li>
      <li><b>ratings_reviews:</b> Stores verified customer ratings (1 to 5 stars), textual comments, booking references, and technician associations.</li>
      <li><b>payments:</b> Records platform financial transactions, payment method (Online / Razorpay, Cash on Delivery, Flex Credit), transaction reference, amount, and settlement status.</li>
      <li><b>flex_memberships:</b> Tracks customer loyalty subscriptions, monthly credit quotas (10 credits/month, 120/year), consumed credits, remaining credits, and 50% rollover rules upon renewal.</li>
      <li><b>safety_incidents:</b> Logs WorkBridge Safe emergency SOS events, including booking ID, triggering user, incident coordinates, emergency contact phone numbers, and resolution audit logs.</li>
      <li><b>provider_locations:</b> Streams real-time GPS coordinate breadcrumbs (latitude, longitude, speed, timestamp) for active en-route technicians.</li>
      <li><b>app_settings:</b> Contains system configuration parameters, commission fee rates, customer support contacts, and version control metadata.</li>
    </ul>
    <p style="text-indent: 25pt;">
      The relationships between these collections maintain referential integrity through foreign keys, ensuring efficient querying, real-time sync, and robust data consistency across the ecosystem.
    </p>
    <div class="page-footer"><span class="footer-left">17 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p23)

# =========================================================================
# PAGE 24: 4.7 MAIN MODULES OF NEW SYSTEM (18 | P a g e)
# =========================================================================
p24 = f"""
<div class="page">
  <div class="page-inner">
    <h2 class="section-title" style="margin-top: 0;">4.7 &nbsp; MAIN MODULES OF NEW SYSTEM</h2>
    <p style="text-indent: 25pt;">
      The <b>WorkBridge</b> platform is architected into three specialized, interconnected modules: <b>Customer Module</b>, <b>Professional (Karigar) Module</b>, and <b>Admin Module</b>. Each module is optimized for its respective user persona to ensure seamless, intuitive operation.
    </p>
    <p style="margin-bottom: 3pt;"><b>1. Customer Module:</b></p>
    <p style="margin-bottom: 4pt;">Designed for domestic homeowners seeking trusted on-demand maintenance services. Key features include:</p>
    <ul>
      <li><b>User Registration &amp; Authentication:</b> Secure onboarding with email, password, and phone OTP verification.</li>
      <li><b>Category Catalog &amp; Search:</b> Instant exploration of 8 trade categories with detailed task descriptions and price ranges.</li>
      <li><b>Flexible Booking Engine:</b> Option to choose between <i>Broadcast Requests</i> (rapid local alert) or <i>Specific Karigar Selection</i>.</li>
      <li><b>Live Geolocation Tracking:</b> Interactive OpenStreetMap showing the assigned technician&rsquo;s real-time transit and arrival ETA.</li>
      <li><b>WorkBridge Safe (SOS):</b> Press-and-hold emergency safety trigger alerting police, trusted contacts, and platform support.</li>
      <li><b>WorkBridge Flex &amp; Share:</b> Credit-based loyalty membership management with 50% renewal rollover and family sharing.</li>
      <li><b>Payments &amp; Digital Invoicing:</b> Razorpay gateway, cash on delivery, and instant itemized digital invoice downloads.</li>
      <li><b>Ratings &amp; Reviews:</b> Verified post-service feedback and star rating submission.</li>
    </ul>
    <p style="margin-bottom: 3pt;"><b>2. Professional (Karigar) Module:</b></p>
    <p style="margin-bottom: 4pt;">Engineered as a digital workplace for skilled blue-collar artisans. Key features include:</p>
    <ul>
      <li><b>KYC Registration:</b> Profile setup with government ID, trade certification, and photo upload for verification.</li>
      <li><b>Real-Time Job Alerts:</b> Audio-visual notification cards for incoming gig requests with 45-second accept/reject timers.</li>
      <li><b>Navigation &amp; Status Control:</b> One-tap route directions and lifecycle status updates (Arrived, In-Progress, Completed).</li>
      <li><b>Earnings &amp; Payouts:</b> Daily and weekly earnings ledger, commission breakdown, and bank payout requests.</li>
      <li><b>Reputation Portfolio:</b> Customer reviews, average rating score, and verified skill badges.</li>
    </ul>
    <p style="margin-bottom: 3pt;"><b>3. Admin Module:</b></p>
    <p style="margin-bottom: 4pt;">Provides platform administrators with complete operational governance. Key features include:</p>
    <ul>
      <li><b>Executive Dashboard:</b> High-level KPI metrics on platform revenue, active bookings, and technician density.</li>
      <li><b>Technician KYC Auditing:</b> Document review workflow to verify, approve, or reject Karigar registrations.</li>
      <li><b>Category &amp; Catalog Control:</b> Dynamic Firestore management of services, trade descriptions, and base rates.</li>
      <li><b>Incident &amp; Dispute Resolution:</b> Immediate safety escalation dashboard to manage WorkBridge Safe SOS alerts.</li>
      <li><b>Financial Analytics:</b> Commission tracking, payout audit logs, and downloadable monthly financial reports.</li>
    </ul>
    <div class="page-footer"><span class="footer-left">18 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p24)

# =========================================================================
# PAGE 25: 5 SYSTEM DESIGN & 5.1 FLOW CHART (19 | P a g e)
# =========================================================================
p25 = f"""
<div class="page">
  <div class="page-inner" style="padding-top: 12mm;">
    <h1 class="chapter-title" style="margin-bottom: 4pt;">5 &nbsp; SYSTEM DESIGN</h1>
    <h2 class="section-title" style="margin-top: 0; margin-bottom: 6pt;">5.1 &nbsp; FLOW CHART</h2>
    <p style="font-size: 10.5pt; line-height: 1.35; margin-bottom: 6pt;">
      The system Flowchart illustrates the end-to-end execution flow of WorkBridge, tracing the customer service request cycle, technician matching and live tracking flow, and administrative supervision.
    </p>
    <div class="diagram-container">
      <img src="{diag_flowchart}" style="max-height: 210mm;" alt="WorkBridge System Flowchart"/>
    </div>
    <div class="page-footer"><span class="footer-left">19 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p25)

# =========================================================================
# PAGE 26: 6 TESTING & 6.1 TESTING PLAN (20 | P a g e)
# =========================================================================
p26 = f"""
<div class="page">
  <div class="page-inner">
    <h1 class="chapter-title">6 &nbsp; TESTING</h1>
    <h2 class="section-title">6.1 &nbsp; TESTING PLAN</h2>
    <p style="text-indent: 25pt;">
      The testing plan for <b>WorkBridge</b> defines the structured validation methodology employed to verify that every software component, user role, and cloud integration functions correctly and fulfills all specified software requirements. The objective of the testing plan is to identify defect conditions early, ensure data integrity across Cloud Firestore, and guarantee smooth performance before mobile deployment.
    </p>
    <p style="text-indent: 25pt;">
      Because WorkBridge is a multi-stakeholder ecosystem with continuous background geolocation streaming, the testing plan spans multiple specialized testing domains: functional module testing, responsive UI testing, GPS map route validation, Firestore security rule enforcement, payment gateway verification, and user acceptance testing across both customers and blue-collar technicians.
    </p>
    <p style="margin-bottom: 6pt;"><b>The main objectives of the testing plan are:</b></p>
    <ul>
      <li>To verify that customer booking workflows—both Broadcast and Specific Karigar requests—dispatch and allocate accurately.</li>
      <li>To validate that user authentication, role enforcement, and session management prevent unauthorized privilege escalation.</li>
      <li>To ensure that real-time geolocation streaming displays accurate technician positions and arrival estimates without application crashes.</li>
      <li>To verify that the <b>WorkBridge Safe</b> emergency SOS trigger operates with complete reliability under simulated emergency conditions.</li>
      <li>To confirm that <b>WorkBridge Flex</b> membership service credits, rollover carry-forward algorithms, and Razorpay transactions compute without ledger discrepancies.</li>
      <li>To validate that form validations reject malformed phone numbers, invalid emails, and empty fields with descriptive error notifications.</li>
      <li>To guarantee that the application remains responsive, fluid, and memory-efficient across standard mobile devices.</li>
    </ul>
    <div class="page-footer"><span class="footer-left">20 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p26)

# =========================================================================
# PAGE 27: 6.2 TESTING STRATEGY (21 | P a g e)
# =========================================================================
p27 = f"""
<div class="page">
  <div class="page-inner">
    <h2 class="section-title" style="margin-top: 0;">6.2 &nbsp; TESTING STRATEGY</h2>
    <p style="text-indent: 25pt;">
      The testing strategy for <b>WorkBridge</b> outlines the techniques, tools, and validation environments used to evaluate the correctness, stability, and security of the system. A balanced combination of <b>Black-Box Testing</b>, <b>White-Box Testing</b>, and <b>Integration Testing</b> was utilized.
    </p>
    <p style="margin-bottom: 4pt;"><b>1. Black-Box Testing</b></p>
    <p style="text-indent: 25pt;">
      Black-box testing focuses on validating functional behavior against the software requirement specifications without examining the underlying Dart source code. Testers supply inputs through the Flutter mobile UI and verify that expected outputs, navigation transitions, and database state updates occur correctly.
    </p>
    <p style="margin-bottom: 3pt;">Black-box testing was primarily utilized to test:</p>
    <ul>
      <li>User registration, login, password recovery, and role redirection (Customer vs Provider vs Admin).</li>
      <li>Trade category exploration, keyword searching, and technician filtering.</li>
      <li>Booking creation modals, date/time pickers, and address input validation.</li>
      <li>Payment gateway dialogs, UPI payment completion, and digital receipt generation.</li>
      <li>WorkBridge Safe interactive press-and-hold button behavior and emergency modal popups.</li>
      <li>Form error messaging when mandatory fields are omitted.</li>
    </ul>
    <p style="margin-bottom: 4pt;"><b>2. White-Box Testing</b></p>
    <p style="text-indent: 25pt;">
      White-box testing focuses on validating internal algorithmic logic, data structures, and code execution paths within Dart and Flutter. Developers analyze execution branching, error catch handlers, and Firestore transactions.
    </p>
    <p style="margin-bottom: 3pt;">Developers tested and verified:</p>
    <ul>
      <li>Provider state management logic in <code>user_controller.dart</code> and booking state notifiers.</li>
      <li>Asynchronous Stream and Future error handling during network dropouts.</li>
      <li>Mathematical algorithms governing WorkBridge Flex 50% credit rollover calculations upon renewal.</li>
      <li>Firestore security rules verifying that non-admin users cannot modify the <code>isVerified</code> flag.</li>
      <li>Coordinate distance calculation algorithms determining nearby provider broadcast radiuses.</li>
    </ul>
    <div class="page-footer"><span class="footer-left">21 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p27)

# =========================================================================
# PAGE 28: 6.2 TESTING STRATEGY (Continued) (22 | P a g e)
# =========================================================================
p28 = f"""
<div class="page">
  <div class="page-inner">
    <h3 class="subsection-title" style="margin-top: 0;">3. Integration Testing</h3>
    <p style="text-indent: 25pt;">
      Integration testing verifies that different modular components of the WorkBridge platform function harmoniously when combined into a unified workflow. This ensures that cross-service dependencies operate without data loss or race conditions.
    </p>
    <p style="margin-bottom: 3pt;">Integration testing included:</p>
    <ul>
      <li><b>Flutter UI and Cloud Firestore Synchronization:</b> Testing that when a customer submits a service request, the Firestore document write immediately triggers the real-time stream listener on the Karigar&rsquo;s device to pop up the job alert card.</li>
      <li><b>Geolocator and Flutter Map Integration:</b> Verifying that continuous location streams from the provider&rsquo;s phone correctly update Realtime Database coordinates and render as a moving marker on the customer&rsquo;s map.</li>
      <li><b>Razorpay Payment Gateway Integration:</b> Ensuring that successful payment webhooks update booking documents from <code>in_progress</code> to <code>completed</code> and record immutable payment transaction receipts.</li>
      <li><b>WorkBridge Safe Notification Pipeline:</b> Validating that triggering an SOS alert synchronously updates the incident database, dials emergency phone intents, and pushes alerts to the Admin Console.</li>
    </ul>
    <h3 class="subsection-title">4. System Testing</h3>
    <p style="text-indent: 25pt;">
      System testing evaluates the WorkBridge application as an end-to-end integrated whole under simulated production conditions. This includes testing system recovery after loss of internet connectivity, memory usage optimization during map navigation, battery consumption profiling, and multi-user concurrency testing.
    </p>
    <h3 class="subsection-title">5. User Acceptance Testing (UAT)</h3>
    <p style="text-indent: 25pt;">
      User Acceptance Testing (UAT) was conducted by inviting actual homeowners and local technicians to test the application in real-world scenarios. Feedback confirmed that the dual booking modes, live map tracking, and simple one-tap job acceptance cards met practical expectations with high satisfaction.
    </p>
    <div class="page-footer"><span class="footer-left">22 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p28)

# =========================================================================
# PAGE 29: 6.3 TESTING METHODS (23 | P a g e)
# =========================================================================
p29 = f"""
<div class="page">
  <div class="page-inner">
    <h2 class="section-title" style="margin-top: 0;">6.3 &nbsp; TESTING METHODS</h2>
    <p style="text-indent: 25pt;">
      To ensure systematic software quality, testing methods were categorized into distinct structural levels:
    </p>
    <p style="margin-bottom: 3pt;"><b>1. Black-Box Testing</b></p>
    <ul>
      <li>Operates independently of internal code visibility.</li>
      <li>Focuses on functional input/output behavior, user flows, and error handling.</li>
      <li>Ensures login, category browsing, booking dispatch, and payment workflows behave as expected.</li>
    </ul>
    <p style="margin-bottom: 3pt;"><b>2. White-Box Testing</b></p>
    <ul>
      <li>Internal validation of Dart code paths, asynchronous streams, and business logic.</li>
      <li>Ensures optimized memory management, robust exception catching, and secure Firestore operations.</li>
    </ul>
    <p style="margin-bottom: 3pt;"><b>3. Unit Testing</b></p>
    <ul>
      <li>Small, isolated Dart functions and model serializers are tested independently.</li>
      <li>Validates models (<code>UserModel</code>, <code>ServiceRequestModel</code>, <code>ServiceCategory</code>), input regex validators, and currency formatters.</li>
    </ul>
    <p style="margin-bottom: 3pt;"><b>4. Integration Testing</b></p>
    <ul>
      <li>Tests interconnected subsystem communication.</li>
      <li>Ensures smooth reactive data flow between Customer, Provider, Admin, Firestore, and Payment Gateways.</li>
    </ul>
    <p style="margin-bottom: 3pt;"><b>5. System Testing</b></p>
    <ul>
      <li>Comprehensive end-to-end evaluation of WorkBridge on physical mobile hardware.</li>
      <li>Verifies cross-device UI responsiveness, GPS accuracy, battery efficiency, and error recovery.</li>
    </ul>
    <p style="margin-bottom: 3pt;"><b>6. User Acceptance Testing (UAT)</b></p>
    <ul>
      <li>Conducted with representative real-world participants (customers and technicians).</li>
      <li>Confirms operational usability, accessibility, intuitiveness, and overall user satisfaction.</li>
    </ul>
    <div class="page-footer"><span class="footer-left">23 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p29)

# =========================================================================
# PAGE 30: 6.4 TEST CASES (Cases 1 to 5) (24 | P a g e)
# =========================================================================
p30 = f"""
<div class="page">
  <div class="page-inner">
    <h2 class="section-title" style="margin-top: 0;">6.4 &nbsp; TEST CASES (Purpose, Required output, Expected Result)</h2>
    
    <div style="font-weight: bold; margin-bottom: 4pt; font-size: 11pt;">Test Case 1: Customer Registration (Valid Credentials)</div>
    <table class="test-case-table">
      <tr><td class="tc-label">Purpose</td><td>To verify that a new customer can successfully register an account</td></tr>
      <tr><td class="tc-label">Required Input</td><td>Valid Name, Email, Phone (+91 9876543210), and Password</td></tr>
      <tr><td class="tc-label">Expected Result</td><td>Account is created in Firebase Auth &amp; Firestore; redirected to Home Dashboard</td></tr>
    </table>

    <div style="font-weight: bold; margin-bottom: 4pt; font-size: 11pt;">Test Case 2: User Login (Invalid Password)</div>
    <table class="test-case-table">
      <tr><td class="tc-label">Purpose</td><td>To ensure that invalid login attempts are securely handled</td></tr>
      <tr><td class="tc-label">Required Input</td><td>Correct Email with incorrect/mismatched password</td></tr>
      <tr><td class="tc-label">Expected Result</td><td>System rejects login and displays &ldquo;Invalid email or password&rdquo; error message</td></tr>
    </table>

    <div style="font-weight: bold; margin-bottom: 4pt; font-size: 11pt;">Test Case 3: Registration Form Validation (Empty Fields)</div>
    <table class="test-case-table">
      <tr><td class="tc-label">Purpose</td><td>To verify that the registration form validates mandatory fields</td></tr>
      <tr><td class="tc-label">Required Input</td><td>Form submitted with empty phone number or malformed email</td></tr>
      <tr><td class="tc-label">Expected Result</td><td>Submission blocked; field-specific validation warnings displayed in red</td></tr>
    </table>

    <div style="font-weight: bold; margin-bottom: 4pt; font-size: 11pt;">Test Case 4: Service Booking Creation (Broadcast Request)</div>
    <table class="test-case-table">
      <tr><td class="tc-label">Purpose</td><td>To verify successful creation of an on-demand broadcast service request</td></tr>
      <tr><td class="tc-label">Required Input</td><td>Category: Plumbing, Title, Address, Schedule Date/Time, Mode: Broadcast</td></tr>
      <tr><td class="tc-label">Expected Result</td><td>Booking document created with status <code>pending</code>; dispatched to local plumbers</td></tr>
    </table>

    <div style="font-weight: bold; margin-bottom: 4pt; font-size: 11pt;">Test Case 5: Direct Karigar Booking (Specific Request)</div>
    <table class="test-case-table">
      <tr><td class="tc-label">Purpose</td><td>To verify direct targeted hiring of a specific service provider</td></tr>
      <tr><td class="tc-label">Required Input</td><td>Target Provider UID (Ramesh Solanki), Task details, Date &amp; Time</td></tr>
      <tr><td class="tc-label">Expected Result</td><td>Request assigned directly to target Karigar; status set to <code>pending</code></td></tr>
    </table>

    <div class="page-footer"><span class="footer-left">24 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p30)

# =========================================================================
# PAGE 31: 6.4 TEST CASES (Cases 6 to 10) (25 | P a g e)
# =========================================================================
p31 = f"""
<div class="page">
  <div class="page-inner">
    <div style="font-weight: bold; margin-bottom: 4pt; font-size: 11pt;">Test Case 6: Karigar Job Request Acceptance</div>
    <table class="test-case-table">
      <tr><td class="tc-label">Purpose</td><td>To verify that a Karigar can accept an incoming job alert</td></tr>
      <tr><td class="tc-label">Required Input</td><td>Provider taps &ldquo;Accept Job&rdquo; button within the 45-second countdown timer</td></tr>
      <tr><td class="tc-label">Expected Result</td><td>Booking status updates to <code>accepted</code>; customer notified; route navigation opened</td></tr>
    </table>

    <div style="font-weight: bold; margin-bottom: 4pt; font-size: 11pt;">Test Case 7: Real-Time Geolocation Tracking &amp; Route Sync</div>
    <table class="test-case-table">
      <tr><td class="tc-label">Purpose</td><td>To verify live GPS coordinate streaming from provider to customer view</td></tr>
      <tr><td class="tc-label">Required Input</td><td>Technician starts transit; location service streams GPS coordinates</td></tr>
      <tr><td class="tc-label">Expected Result</td><td>Customer map reflects technician marker movement and dynamic arrival ETA</td></tr>
    </table>

    <div style="font-weight: bold; margin-bottom: 4pt; font-size: 11pt;">Test Case 8: WorkBridge Safe SOS Emergency Alert Trigger</div>
    <table class="test-case-table">
      <tr><td class="tc-label">Purpose</td><td>To ensure the emergency SOS safety protocol functions with high reliability</td></tr>
      <tr><td class="tc-label">Required Input</td><td>Customer presses and holds SOS button for 3 continuous seconds</td></tr>
      <tr><td class="tc-label">Expected Result</td><td>Emergency dialer launched; SMS sent to trusted contact; incident logged in Admin Hub</td></tr>
    </table>

    <div style="font-weight: bold; margin-bottom: 4pt; font-size: 11pt;">Test Case 9: WorkBridge Flex Credit Deduction &amp; 50% Rollover</div>
    <table class="test-case-table">
      <tr><td class="tc-label">Purpose</td><td>To verify credit ledger updates and rollover calculation upon renewal</td></tr>
      <tr><td class="tc-label">Required Input</td><td>Customer books via Flex Credit (10 remaining); membership cycle renews</td></tr>
      <tr><td class="tc-label">Expected Result</td><td>1 credit deducted; remaining 9 credits roll over at 50% (4.5 &rarr; 5 credits) into new cycle</td></tr>
    </table>

    <div style="font-weight: bold; margin-bottom: 4pt; font-size: 11pt;">Test Case 10: Online Payment &amp; Review Submission</div>
    <table class="test-case-table">
      <tr><td class="tc-label">Purpose</td><td>To verify payment completion and customer review storage</td></tr>
      <tr><td class="tc-label">Required Input</td><td>Customer completes payment via Razorpay and submits 5-star rating with review</td></tr>
      <tr><td class="tc-label">Expected Result</td><td>Payment verified; booking set to <code>completed</code>; review added to provider profile</td></tr>
    </table>

    <div class="page-footer"><span class="footer-left">25 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p31)

# =========================================================================
# PAGE 32: 7 SCREENSHOTS - USER SIDE Home page (26 | P a g e)
# =========================================================================
p32 = f"""
<div class="page">
  <div class="page-inner" style="text-align: center;">
    <h1 class="chapter-title" style="margin-bottom: 4pt;">7 &nbsp; SCREENSHOTS</h1>
    <div class="screenshot-subtitle">USER SIDE</div>
    <div class="screenshot-title">Home page</div>
    <div class="screenshot-container" style="margin-top: 10pt;">
      <img src="{screen_home}" style="max-height: 180mm;" alt="WorkBridge Customer Home Page"/>
    </div>
    <div class="page-footer"><span class="footer-left">26 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p32)

# =========================================================================
# PAGE 33: Login page & Register page (27 | P a g e)
# =========================================================================
p33 = f"""
<div class="page">
  <div class="page-inner" style="text-align: center;">
    <div class="screenshot-title" style="margin-top: 0;">Login page &amp; Register page</div>
    <div class="screenshot-container" style="margin-top: 6pt;">
      <img src="{screen_auth}" style="max-height: 195mm;" alt="WorkBridge Login and Registration Screens"/>
    </div>
    <div class="page-footer"><span class="footer-left">27 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p33)

# =========================================================================
# PAGE 34: Reset password page & OTP Verification (28 | P a g e)
# =========================================================================
p34 = f"""
<div class="page">
  <div class="page-inner" style="text-align: center;">
    <div class="screenshot-title" style="margin-top: 0;">Reset password page &amp; OTP Verification</div>
    <div class="screenshot-container" style="margin-top: 6pt;">
      <img src="{screen_password}" style="max-height: 195mm;" alt="WorkBridge Password Reset Screens"/>
    </div>
    <div class="page-footer"><span class="footer-left">28 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p34)

# =========================================================================
# PAGE 35: Service Categories page (29 | P a g e)
# =========================================================================
p35 = f"""
<div class="page">
  <div class="page-inner" style="text-align: center;">
    <div class="screenshot-title" style="margin-top: 0;">Service Categories page</div>
    <div class="screenshot-container" style="margin-top: 10pt;">
      <img src="{screen_catalog}" style="max-height: 195mm;" alt="WorkBridge Service Categories Screen"/>
    </div>
    <div class="page-footer"><span class="footer-left">29 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p35)

# =========================================================================
# PAGE 36: Professional Details page (30 | P a g e)
# =========================================================================
p36 = f"""
<div class="page">
  <div class="page-inner" style="text-align: center;">
    <div class="screenshot-title" style="margin-top: 0;">Professional Details page</div>
    <div class="screenshot-container" style="margin-top: 10pt;">
      <img src="{screen_provider_details}" style="max-height: 195mm;" alt="WorkBridge Professional Profile Details Screen"/>
    </div>
    <div class="page-footer"><span class="footer-left">30 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p36)

# =========================================================================
# PAGE 37: Service Booking Modal (Broadcast vs Specific) (31 | P a g e)
# =========================================================================
p37 = f"""
<div class="page">
  <div class="page-inner" style="text-align: center;">
    <div class="screenshot-title" style="margin-top: 0;">Service Booking Modal (Broadcast vs Specific)</div>
    <div class="screenshot-container" style="margin-top: 6pt;">
      <img src="{screen_booking_modal}" style="max-height: 195mm;" alt="WorkBridge Service Booking Modal Screens"/>
    </div>
    <div class="page-footer"><span class="footer-left">31 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p37)

# =========================================================================
# PAGE 38: Checkout page & Online Payment (Razorpay) (32 | P a g e)
# =========================================================================
p38 = f"""
<div class="page">
  <div class="page-inner" style="text-align: center;">
    <div class="screenshot-title" style="margin-top: 0;">Checkout page &amp; Online Payment (Razorpay)</div>
    <div class="screenshot-container" style="margin-top: 6pt;">
      <img src="{screen_checkout}" style="max-height: 195mm;" alt="WorkBridge Checkout and Payment Screens"/>
    </div>
    <div class="page-footer"><span class="footer-left">32 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p38)

# =========================================================================
# PAGE 39: Customer Profile page & Orders/Bookings list (33 | P a g e)
# =========================================================================
p39 = f"""
<div class="page">
  <div class="page-inner" style="text-align: center;">
    <div class="screenshot-title" style="margin-top: 0;">Customer Profile page &amp; Bookings list</div>
    <div class="screenshot-container" style="margin-top: 6pt;">
      <img src="{screen_profile}" style="max-height: 195mm;" alt="WorkBridge Customer Profile and Bookings Screens"/>
    </div>
    <div class="page-footer"><span class="footer-left">33 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p39)

# =========================================================================
# PAGE 40: Booking Details & Status Lifecycle Timeline (34 | P a g e)
# =========================================================================
p40 = f"""
<div class="page">
  <div class="page-inner" style="text-align: center;">
    <div class="screenshot-title" style="margin-top: 0;">Booking Details &amp; Lifecycle Timeline</div>
    <div class="screenshot-container" style="margin-top: 10pt;">
      <img src="{screen_lifecycle}" style="max-height: 195mm;" alt="WorkBridge Booking Details and Status Timeline"/>
    </div>
    <div class="page-footer"><span class="footer-left">34 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p40)

# =========================================================================
# PAGE 41: Live Geolocation Tracking Map (35 | P a g e)
# =========================================================================
p41 = f"""
<div class="page">
  <div class="page-inner" style="text-align: center;">
    <div class="screenshot-title" style="margin-top: 0;">Live Geolocation Tracking Map</div>
    <div class="screenshot-container" style="margin-top: 10pt;">
      <img src="{screen_tracking_map}" style="max-height: 195mm;" alt="WorkBridge Live Map Tracking Screen"/>
    </div>
    <div class="page-footer"><span class="footer-left">35 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p41)

# =========================================================================
# PAGE 42: WorkBridge Flex Membership (Service Credits) (36 | P a g e)
# =========================================================================
p42 = f"""
<div class="page">
  <div class="page-inner" style="text-align: center;">
    <div class="screenshot-title" style="margin-top: 0;">WorkBridge Flex Membership (Service Credits)</div>
    <div class="screenshot-container" style="margin-top: 10pt;">
      <img src="{screen_flex}" style="max-height: 195mm;" alt="WorkBridge Flex Membership Screen"/>
    </div>
    <div class="page-footer"><span class="footer-left">36 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p42)

# =========================================================================
# PAGE 43: WorkBridge Safe (SOS Emergency Protocol) (37 | P a g e)
# =========================================================================
p43 = f"""
<div class="page">
  <div class="page-inner" style="text-align: center;">
    <div class="screenshot-title" style="margin-top: 0;">WorkBridge Safe (SOS Emergency Protocol)</div>
    <div class="screenshot-container" style="margin-top: 10pt;">
      <img src="{screen_safe}" style="max-height: 195mm;" alt="WorkBridge Safe Emergency Protocol Screen"/>
    </div>
    <div class="page-footer"><span class="footer-left">37 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p43)

# =========================================================================
# PAGE 44: ADMIN SIDE - Dashboard page & Service Provider Management (38 | P a g e)
# =========================================================================
p44 = f"""
<div class="page">
  <div class="page-inner" style="text-align: center;">
    <div class="screenshot-subtitle" style="margin-top: 0;">ADMIN SIDE</div>
    <div class="screenshot-title">Executive Dashboard page</div>
    <div class="screenshot-container" style="margin-top: 8pt;">
      <img src="{screen_admin_dashboard}" style="max-height: 195mm;" alt="WorkBridge Admin Executive Dashboard"/>
    </div>
    <div class="page-footer"><span class="footer-left">38 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p44)

# =========================================================================
# PAGE 45: Add Service Category & Data Hub (39 | P a g e)
# =========================================================================
p45 = f"""
<div class="page">
  <div class="page-inner" style="text-align: center;">
    <div class="screenshot-title" style="margin-top: 0;">Admin Data Management Screen (Data Hub)</div>
    <div class="screenshot-container" style="margin-top: 8pt;">
      <img src="{screen_admin_data}" style="max-height: 195mm;" alt="WorkBridge Administrative Data Management Screen"/>
    </div>
    <div class="page-footer"><span class="footer-left">39 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p45)

# =========================================================================
# PAGE 46: Booking Management & Live Gigs Oversight (40 | P a g e)
# =========================================================================
p46 = f"""
<div class="page">
  <div class="page-inner" style="text-align: center;">
    <div class="screenshot-title" style="margin-top: 0;">Booking Management &amp; Live Gigs Oversight</div>
    <div class="screenshot-container" style="margin-top: 8pt;">
      <img src="{screen_admin_dashboard}" style="max-height: 195mm;" alt="WorkBridge Booking Oversight Screen"/>
    </div>
    <div class="page-footer"><span class="footer-left">40 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p46)

# =========================================================================
# PAGE 47: User Management & Platform Revenue Analytics (41 | P a g e)
# =========================================================================
p47 = f"""
<div class="page">
  <div class="page-inner" style="text-align: center;">
    <div class="screenshot-title" style="margin-top: 0;">User Management &amp; Revenue Analytics</div>
    <div class="screenshot-container" style="margin-top: 8pt;">
      <img src="{screen_admin_data}" style="max-height: 195mm;" alt="WorkBridge User Management and Revenue Reports"/>
    </div>
    <div class="page-footer"><span class="footer-left">41 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p47)

# =========================================================================
# PAGE 48: Karigar Console & Job Requests Acceptance (42 | P a g e)
# =========================================================================
p48 = f"""
<div class="page">
  <div class="page-inner" style="text-align: center;">
    <div class="screenshot-subtitle" style="margin-top: 0;">PROFESSIONAL SIDE</div>
    <div class="screenshot-title">Karigar Console &amp; Job Requests Acceptance</div>
    <div class="screenshot-container" style="margin-top: 8pt;">
      <img src="{screen_karigar}" style="max-height: 195mm;" alt="WorkBridge Karigar Console and Job Alerts"/>
    </div>
    <div class="page-footer"><span class="footer-left">42 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p48)

# =========================================================================
# PAGE 49: 8 LIMITATION AND FUTURE ENHANCEMENT (43 | P a g e)
# =========================================================================
p49 = f"""
<div class="page">
  <div class="page-inner">
    <h1 class="chapter-title">8 &nbsp; LIMITATION AND FUTURE ENHANCEMENT</h1>
    <h2 class="section-title" style="margin-top: 8pt;">Limitations</h2>
    <ul>
      <li><b>Internet &amp; Connectivity Dependency:</b> The application requires continuous smartphone cellular data or Wi-Fi to synchronize real-time Cloud Firestore updates and map tiles.</li>
      <li><b>GPS Signal Accuracy:</b> In dense high-rise apartment complexes or basement levels, satellite GPS attenuation may cause minor temporary fluctuations in technician location tracking.</li>
      <li><b>Third-Party Gateway Dependencies:</b> Online cashless payment processing depends on the external server uptime and network latency of the Razorpay payment infrastructure.</li>
      <li><b>Initial Technician Geographic Density:</b> In newly launched suburban territories, broadcast request fulfillment speed is influenced by the density of nearby onboarded Karigars.</li>
      <li><b>Battery Consumption During Continuous Tracking:</b> High-frequency GPS polling on low-tier technician smartphones may increase device battery drain over extended working shifts.</li>
    </ul>

    <h2 class="section-title" style="margin-top: 14pt;">Future Enhancements</h2>
    <ul>
      <li><b>AI-Powered Safety Intelligence:</b> Integration of machine learning models to detect anomalies during active service visits (e.g. unexpected route deviations or abnormally prolonged job durations) to alert human safety teams preemptively.</li>
      <li><b>AI-Based Smart Matchmaking:</b> Machine learning algorithms that match customer service requests with technicians based on proximity, past review sentiment, and historic completion velocity.</li>
      <li><b>Multi-Lingual Voice Assistant:</b> Implementing local language voice-activated job acceptance and turn-by-turn spoken navigation for Karigars with lower text literacy.</li>
      <li><b>Automated Biometric KYC Verification:</b> Integrating automated government Aadhaar and facial recognition verification APIs to accelerate technician onboarding.</li>
      <li><b>Expanded Commercial &amp; Multi-City Marketplace:</b> Scaling WorkBridge from domestic residential maintenance into commercial property facility management across major metropolitan hubs.</li>
    </ul>
    <div class="page-footer"><span class="footer-left">43 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p49)

# =========================================================================
# PAGE 50: 9 CONCLUSION AND DISCUSSION (44 | P a g e)
# =========================================================================
p50 = f"""
<div class="page">
  <div class="page-inner">
    <h1 class="chapter-title">9 &nbsp; CONCLUSION AND DISCUSSION</h1>
    <p style="text-indent: 25pt;">
      The <b>WorkBridge</b> system successfully provides an advanced, dependable, and equitable digital solution for the on-demand home services industry. By replacing antiquated, disorganized word-of-mouth practices with a transparent mobile marketplace, the platform eliminates search friction, standardizes service pricing, introduces rigorous accountability, and significantly improves safety for household consumers.
    </p>
    <p style="text-indent: 25pt;">
      The adoption of modern engineering technologies—specifically <b>Flutter</b>, <b>Dart</b>, and <b>Google Firebase</b>—enabled the platform to deliver high runtime performance, fluid cross-platform responsiveness, and resilient real-time cloud data synchronization. The system supports multi-role access control, dynamic trade category discovery, dual booking dispatching (Broadcast vs Specific Karigar), live OpenStreetMap route tracking, cashless payment processing, WorkBridge Flex loyalty memberships, and the <b>WorkBridge Safe</b> emergency SOS safety protocol.
    </p>
    <p style="text-indent: 25pt;">
      From a discussion perspective, WorkBridge directly resolves the longstanding socio-economic challenges that characterize the informal blue-collar economy. By granting independent artisans (Karigars) a dignified digital presence, verified skill credentials, and transparent direct earnings, the platform fosters inclusive economic empowerment while freeing technicians from exploitative intermediaries. For homeowners, the combination of upfront price estimates, live technician GPS tracking, and dedicated in-service safety mechanisms establishes an unprecedented standard of consumer confidence.
    </p>
    <p style="text-indent: 25pt;">
      In conclusion, <b>WorkBridge</b> is a practical, highly scalable, and user-centric software solution that fulfills all functional, architectural, and academic requirements. With proposed future additions such as AI safety anomaly detection and multi-lingual voice navigation, WorkBridge possesses immense commercial potential to become a leading enterprise ecosystem for the modern gig economy.
    </p>
    <div class="page-footer"><span class="footer-left">44 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p50)

# =========================================================================
# PAGE 51: 10 REFERENCES (45 | P a g e)
# =========================================================================
p51 = f"""
<div class="page">
  <div class="page-inner">
    <h1 class="chapter-title">10 &nbsp; REFERENCES</h1>
    
    <div style="margin-bottom: 12pt;">
      <div style="font-weight: bold; font-size: 11.5pt;">1. Flutter &ndash; Official Documentation</div>
      <div style="color: #0284C7; font-size: 10.5pt; margin: 2pt 0;">https://flutter.dev/docs</div>
      <p style="font-size: 11pt; line-height: 1.4; margin: 0;">
        Flutter documentation was utilized to implement cross-platform reactive mobile UI widgets, state lifecycle management, custom painters, and native build configurations.
      </p>
    </div>

    <div style="margin-bottom: 12pt;">
      <div style="font-weight: bold; font-size: 11.5pt;">2. Google Firebase &ndash; Cloud Firestore &amp; Auth Documentation</div>
      <div style="color: #0284C7; font-size: 10.5pt; margin: 2pt 0;">https://firebase.google.com/docs</div>
      <p style="font-size: 11pt; line-height: 1.4; margin: 0;">
        Firebase documentation was referenced for NoSQL document modeling, real-time snapshot streams, token authentication, and cloud security rules.
      </p>
    </div>

    <div style="margin-bottom: 12pt;">
      <div style="font-weight: bold; font-size: 11.5pt;">3. OpenStreetMap &amp; Flutter Map Documentation</div>
      <div style="color: #0284C7; font-size: 10.5pt; margin: 2pt 0;">https://docs.fleaflet.dev/</div>
      <p style="font-size: 11pt; line-height: 1.4; margin: 0;">
        Referred for interactive map tile rendering, marker coordinate placement, polyline route drawing, and geolocation integration.
      </p>
    </div>

    <div style="margin-bottom: 12pt;">
      <div style="font-weight: bold; font-size: 11.5pt;">4. Razorpay &ndash; Payment Gateway Developer Documentation</div>
      <div style="color: #0284C7; font-size: 10.5pt; margin: 2pt 0;">https://razorpay.com/docs/</div>
      <p style="font-size: 11pt; line-height: 1.4; margin: 0;">
        Razorpay documentation was used for integrating secure UPI, card, and net banking payment flows, webhooks, and digital transaction verification.
      </p>
    </div>

    <div style="margin-bottom: 12pt;">
      <div style="font-weight: bold; font-size: 11.5pt;">5. GitHub &ndash; Codebase &amp; Architecture Reference</div>
      <div style="color: #0284C7; font-size: 10.5pt; margin: 2pt 0;">https://github.com/</div>
      <p style="font-size: 11pt; line-height: 1.4; margin: 0;">
        GitHub open-source repositories were referenced for studying Clean Architecture design patterns, Provider state notifiers, and repository abstractions in Flutter.
      </p>
    </div>

    <div class="page-footer"><span class="footer-left">45 | P a g e</span></div>
  </div>
</div>
"""
HTML_PAGES.append(p51)

# Assemble Complete HTML
FULL_HTML = HTML_HEAD + "\n".join(HTML_PAGES) + "\n</body>\n</html>"

out_html_path = os.path.join(REPORT_DIR, "WorkBridge_Project_Report.html")
with open(out_html_path, "w", encoding="utf-8") as f:
    f.write(FULL_HTML)

print(f"Report HTML written to {out_html_path} ({len(FULL_HTML)} bytes, {len(HTML_PAGES)} pages)")

# Compile to PDF using Chrome Headless
out_pdf_path = os.path.join(REPORT_DIR, "WorkBridge_Project_Report.pdf")
cmd = [
    CHROME_PATH,
    "--headless=new",
    "--no-sandbox",
    "--disable-gpu",
    f"--print-to-pdf={out_pdf_path}",
    "--no-pdf-header-footer",
    os.path.abspath(out_html_path)
]
res = subprocess.run(cmd, capture_output=True, text=True)
if res.returncode == 0 and os.path.exists(out_pdf_path):
    print(f"Generated WorkBridge PDF: {out_pdf_path} ({os.path.getsize(out_pdf_path)} bytes)")
else:
    print(f"Failed to generate PDF: {res.stderr}")

