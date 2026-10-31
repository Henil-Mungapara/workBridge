"""
Generate complete editable WorkBridge Project Report in DOCX format.
"""

import os
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

DOCX_OUT = r"e:\workbridge\WorkBridge_Project_Report.docx"
DIAGRAMS_DIR = r"e:\workbridge\report_assets\diagrams"
SCREENS_DIR = r"e:\workbridge\report_assets\screens"

doc = docx.Document()

# Page Margins (A4)
section = doc.sections[0]
section.page_width = Inches(8.27)
section.page_height = Inches(11.69)
section.top_margin = Inches(0.8)
section.bottom_margin = Inches(0.8)
section.left_margin = Inches(0.9)
section.right_margin = Inches(0.9)

# Default Style Settings
normal_style = doc.styles['Normal']
normal_style.font.name = 'Times New Roman'
normal_style.font.size = Pt(12)
normal_style.font.color.rgb = RGBColor(0, 0, 0)
normal_style.paragraph_format.line_spacing = 1.3
normal_style.paragraph_format.space_after = Pt(8)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = OxmlElement('w:tcMar')
    for m, val in [('w:top', top), ('w:bottom', bottom), ('w:left', left), ('w:right', right)]:
        node = OxmlElement(m)
        node.set(qn('w:w'), str(val))
        node.set(qn('w:type'), 'dxa')
        tcMar.append(node)
    tcPr.append(tcMar)

def set_cell_border(cell, **kwargs):
    """
    kwargs: top, bottom, left, right
    values: dict(sz=12, val='single', color='000000')
    """
    tcPr = cell._tc.get_or_add_tcPr()
    tcBorders = OxmlElement('w:tcBorders')
    for edge in ('top', 'left', 'bottom', 'right', 'insideH', 'insideV'):
        edge_data = kwargs.get(edge)
        if edge_data:
            tag = f'w:{edge}'
            element = OxmlElement(tag)
            element.set(qn('w:val'), edge_data.get('val', 'single'))
            element.set(qn('w:sz'), str(edge_data.get('sz', 4)))
            element.set(qn('w:space'), '0')
            element.set(qn('w:color'), edge_data.get('color', 'auto'))
            tcBorders.append(element)
    tcPr.append(tcBorders)

def add_chapter_title(text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(12)
    p.paragraph_format.space_after = Pt(8)
    run = p.add_run(text)
    run.font.name = 'Times New Roman'
    run.font.size = Pt(16)
    run.font.bold = True
    return p

def add_section_title(text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(10)
    p.paragraph_format.space_after = Pt(6)
    run = p.add_run(text)
    run.font.name = 'Times New Roman'
    run.font.size = Pt(13.5)
    run.font.bold = True
    return p

def add_subsection_title(text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(8)
    p.paragraph_format.space_after = Pt(4)
    run = p.add_run(text)
    run.font.name = 'Times New Roman'
    run.font.size = Pt(12.5)
    run.font.bold = True
    return p

def add_justified_para(text, indent=True):
    p = doc.add_paragraph()
    p.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    p.paragraph_format.space_after = Pt(8)
    if indent:
        p.paragraph_format.first_line_indent = Inches(0.4)
    run = p.add_run(text)
    run.font.name = 'Times New Roman'
    run.font.size = Pt(12)
    return p

def add_bullet_point(bold_prefix, text):
    p = doc.add_paragraph(style='List Bullet')
    p.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    p.paragraph_format.space_after = Pt(4)
    if bold_prefix:
        r_b = p.add_run(bold_prefix)
        r_b.font.name = 'Times New Roman'
        r_b.font.size = Pt(12)
        r_b.font.bold = True
    r_t = p.add_run(text)
    r_t.font.name = 'Times New Roman'
    r_t.font.size = Pt(12)
    return p

# -------------------------------------------------------------
# PAGE 1: COVER PAGE
# -------------------------------------------------------------
logo_top = r"e:\workbridge\extracted_pdf_images\img_0.jpg"
logo_bot = r"e:\workbridge\extracted_pdf_images\img_1.jpg"

if os.path.exists(logo_top):
    p_logo = doc.add_paragraph()
    p_logo.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_logo.paragraph_format.space_before = Pt(10)
    p_logo.paragraph_format.space_after = Pt(10)
    run_logo = p_logo.add_run()
    run_logo.add_picture(logo_top, width=Inches(1.5))

p_title = doc.add_paragraph()
p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
p_title.paragraph_format.space_before = Pt(16)
p_title.paragraph_format.space_after = Pt(16)
run_title = p_title.add_run("WorkBridge – Service Marketplace")
run_title.font.name = 'Times New Roman'
run_title.font.size = Pt(22)
run_title.font.bold = True

p_sub = doc.add_paragraph()
p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
p_sub.paragraph_format.space_after = Pt(14)
run_sub = p_sub.add_run(
    "A PROJECT REPORT SUBMITTED IN PARTIAL FULFILLMENT OF THE REQUIREMENT\n"
    "FOR THE AWARD OF THE DEGREE OF\n"
    "SCHOOL OF ENGINEERING RK UNIVERSITY, RAJKOT\n\n"
    "SUBMITTED BY"
)
run_sub.font.name = 'Times New Roman'
run_sub.font.size = Pt(11)
run_sub.font.bold = True

# Student Table
tbl_student = doc.add_table(rows=2, cols=2)
tbl_student.alignment = WD_TABLE_ALIGNMENT.CENTER
tbl_student.rows[0].cells[0].paragraphs[0].text = "NAME:"
tbl_student.rows[0].cells[0].paragraphs[0].runs[0].font.bold = True
tbl_student.rows[0].cells[1].paragraphs[0].text = "ENROLLMENT NO:"
tbl_student.rows[0].cells[1].paragraphs[0].runs[0].font.bold = True
tbl_student.rows[1].cells[0].paragraphs[0].text = "Henil Mungapara"
tbl_student.rows[1].cells[1].paragraphs[0].text = "25SOECA21060"

p_guidance = doc.add_paragraph()
p_guidance.alignment = WD_ALIGN_PARAGRAPH.CENTER
p_guidance.paragraph_format.space_before = Pt(20)
p_guidance.paragraph_format.space_after = Pt(8)
r_g = p_guidance.add_run("UNDER THE GUIDANCE OF")
r_g.font.name = 'Times New Roman'
r_g.font.size = Pt(12)
r_g.font.bold = True

tbl_guide = doc.add_table(rows=1, cols=2)
tbl_guide.alignment = WD_TABLE_ALIGNMENT.CENTER
tbl_guide.rows[0].cells[0].paragraphs[0].text = (
    "Prof. Parvez Belim Sir\n"
    "Assistant Professor,\n"
    "School of Engineering,\n"
    "RK University, Rajkot."
)
tbl_guide.rows[0].cells[0].paragraphs[0].runs[0].font.bold = True
tbl_guide.rows[0].cells[1].paragraphs[0].text = (
    "Prof. Paresh Tanna\n"
    "HOD(Head of Department),\n"
    "School of Engineering,\n"
    "RK University, Rajkot."
)
tbl_guide.rows[0].cells[1].paragraphs[0].runs[0].font.bold = True

if os.path.exists(logo_bot):
    p_blogo = doc.add_paragraph()
    p_blogo.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_blogo.paragraph_format.space_before = Pt(20)
    p_blogo.paragraph_format.space_after = Pt(4)
    run_blogo = p_blogo.add_run()
    run_blogo.add_picture(logo_bot, width=Inches(1.8))

p_inst = doc.add_paragraph()
p_inst.alignment = WD_ALIGN_PARAGRAPH.CENTER
r_inst = p_inst.add_run("SCHOOL OF ENGINEERING, RK UNIVERSITY, RAJKOT")
r_inst.font.name = 'Times New Roman'
r_inst.font.size = Pt(11)
r_inst.font.bold = True

doc.add_page_break()

# -------------------------------------------------------------
# PAGE 2: DECLARATION
# -------------------------------------------------------------
if os.path.exists(logo_top):
    p_dlogo = doc.add_paragraph()
    p_dlogo.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_dlogo.paragraph_format.space_before = Pt(10)
    p_dlogo.paragraph_format.space_after = Pt(10)
    p_dlogo.add_run().add_picture(logo_top, width=Inches(1.4))

p_dec = doc.add_paragraph()
p_dec.alignment = WD_ALIGN_PARAGRAPH.CENTER
p_dec.paragraph_format.space_after = Pt(16)
r_dec = p_dec.add_run("DECLARATION")
r_dec.font.name = 'Times New Roman'
r_dec.font.size = Pt(15)
r_dec.font.bold = True

add_justified_para(
    "I am here to certify that I am the sole author of this project work and that neither any part "
    "of this project work nor the whole of the project work has been submitted for a degree to any "
    "other University or Institution. I certify that, to the best of my knowledge, my project work does "
    "not infringe upon anyone’s copyright nor violate any proprietary rights and that any ideas, "
    "techniques, quotations, or any other material from the work of other people included in my "
    "project document, published or otherwise, is fully acknowledged in accordance with the standard "
    "referencing practices. I declare that this is a true copy of my project work, including any final "
    "revisions, as approved by my project review committee."
)

p_by = doc.add_paragraph()
p_by.paragraph_format.space_before = Pt(24)
p_by.add_run("Project By\n").font.bold = True
p_by.add_run("Henil Mungapara [ 25SOECA21060 ]\n\n").font.bold = True
p_by.add_run("Date: -  20/04/2026").font.bold = True

doc.add_page_break()

# -------------------------------------------------------------
# PAGE 3 & 4: TABLE OF CONTENTS
# -------------------------------------------------------------
p_toc = doc.add_paragraph()
p_toc.alignment = WD_ALIGN_PARAGRAPH.CENTER
p_toc.paragraph_format.space_after = Pt(12)
r_toc = p_toc.add_run("TABLE OF CONTENTS")
r_toc.font.name = 'Times New Roman'
r_toc.font.size = Pt(15)
r_toc.font.bold = True

toc_data = [
    ("ACKNOWLEDGEMENT", ""),
    ("ABSTRACT", ""),
    ("1. INTRODUCTION", "1"),
    ("  1.1 PROJECT SUMMARY", "1"),
    ("  1.2 PURPOSE", "2"),
    ("  1.3 TECHNOLOGY: FLUTTER, DART, FIREBASE", "3"),
    ("2. PROJECT MANAGEMENT", "4"),
    ("  2.1 PROJECT PLANNING AND SCHEDULING", "4"),
    ("    2.1.1 PROJECT DEVELOPMENT APPROACH", "5"),
    ("    2.1.2 PROJECT PLAN", "6"),
    ("    2.1.3 SCHEDULE REPRESENTATION", "7"),
    ("3. SYSTEM REQUIREMENTS STUDY", "8"),
    ("  3.1 USER CHARACTERISTICS", "8"),
    ("  3.2 HARDWARE AND SOFTWARE REQUIREMENTS", "9"),
    ("4. SYSTEM ANALYSIS", "10"),
    ("  4.1 STUDY OF CURRENT SYSTEM", "10"),
    ("  4.2 PROBLEM & WEAKNESS OF CURRENT SYSTEM", "11"),
    ("  4.3 FEASIBILITY STUDY", "12"),
    ("  4.4 REQUIREMENT VALIDATION", "13"),
    ("  4.5 FUNCTION SYSTEM", "14"),
    ("    4.5.1 E-R DIAGRAM", "14"),
    ("    4.5.2 USE CASE DIAGRAM", "15"),
    ("    4.5.3 DATA FLOW DIAGRAM", "16"),
    ("  4.6 DATA MODELING", "17"),
    ("  4.7 MAIN MODULES OF NEW SYSTEM", "18"),
    ("5. SYSTEM DESIGN", "19"),
    ("  5.1 FLOW CHART", "19"),
    ("6. TESTING", "20"),
    ("  6.1 TEST PLAN", "21"),
    ("  6.2 TESTING STRATEGY", "22"),
    ("  6.3 TESTING METHODS", "23"),
    ("  6.4 TESTING CASES", "24"),
    ("7. SCREEN SHOTS", "26"),
    ("8. LIMITATION & FUTURE ENHANCEMENT", "43"),
    ("9. CONCLUSION AND DISCUSSION", "44"),
    ("10 REFERENCES", "45"),
]

tbl_toc = doc.add_table(rows=len(toc_data), cols=2)
tbl_toc.alignment = WD_TABLE_ALIGNMENT.CENTER
for idx, (title, page) in enumerate(toc_data):
    cell_t = tbl_toc.rows[idx].cells[0]
    cell_p = tbl_toc.rows[idx].cells[1]
    cell_t.paragraphs[0].text = title
    cell_p.paragraphs[0].text = page
    cell_p.paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
    if title.startswith("1.") or title.startswith("2.") or title.startswith("3.") or \
       title.startswith("4.") or title.startswith("5.") or title.startswith("6.") or \
       title.startswith("7.") or title.startswith("8.") or title.startswith("9.") or \
       title.startswith("10") or title == "ACKNOWLEDGEMENT" or title == "ABSTRACT":
        cell_t.paragraphs[0].runs[0].font.bold = True
        if cell_p.paragraphs[0].runs:
            cell_p.paragraphs[0].runs[0].font.bold = True

doc.add_page_break()

# -------------------------------------------------------------
# PAGE 5: ACKNOWLEDGEMENT
# -------------------------------------------------------------
p_ack = doc.add_paragraph()
p_ack.alignment = WD_ALIGN_PARAGRAPH.CENTER
p_ack.paragraph_format.space_before = Pt(20)
p_ack.paragraph_format.space_after = Pt(18)
r_ack = p_ack.add_run("ACKNOWLEDGEMENT")
r_ack.font.name = 'Times New Roman'
r_ack.font.size = Pt(15)
r_ack.font.bold = True

add_justified_para(
    "The success and outcome of this project required a lot of guidance and assistance from many people, "
    "and I am extremely fortunate to have got this all along the completion of my project work. Whatever I have done "
    "is only due to such guidance and assistance and I will not forget to thank them."
)
add_justified_para(
    "I respect and thank RK University for giving me an opportunity to do the project work in MCA and "
    "providing me with all support and guidance which made me complete the project on time. I am extremely grateful "
    "to the university for providing such nice support and guidance."
)
add_justified_para(
    "I also thank my internal project guide, Prof. Parvez Belim Sir, Assistant Professor, RK University Rajkot, "
    "for his invaluable guidance, continuous support, and constructive suggestions during this project work."
)
add_justified_para(
    "I express my sincere thanks to Prof. Paresh Tanna, Head of Department (HOD), School of Engineering, "
    "RK University Rajkot, for his encouragement and administrative backing throughout the course of this project."
)
add_justified_para(
    "I am thankful to and fortunate enough to get constant encouragement, support and guidance from all teaching "
    "and technical staff of Department of Master of Computer Application which helped me in successfully completing my project work."
)

doc.add_page_break()

# -------------------------------------------------------------
# PAGE 6: ABSTRACT
# -------------------------------------------------------------
p_abs = doc.add_paragraph()
p_abs.alignment = WD_ALIGN_PARAGRAPH.CENTER
p_abs.paragraph_format.space_before = Pt(16)
p_abs.paragraph_format.space_after = Pt(14)
r_abs = p_abs.add_run("ABSTRACT")
r_abs.font.name = 'Times New Roman'
r_abs.font.size = Pt(15)
r_abs.font.bold = True

add_justified_para(
    "The WorkBridge system is an advanced on-demand service marketplace mobile application developed using "
    "Flutter and Firebase technologies. The primary objective of this system is to simplify and modernize the home and "
    "commercial maintenance industry by connecting everyday consumers with skilled, verified local professionals (Karigars)—such as "
    "plumbers, electricians, carpenters, painters, appliance technicians, and cleaning specialists. The system reduces manual discovery "
    "effort, eliminates arbitrary middleman charges, and allows users to hire reliable technicians conveniently from anywhere."
)
add_justified_para(
    "The application provides an efficient multi-workflow platform supporting two flexible booking paradigms: broadcast dispatching "
    "(broadcasting urgent requests to all nearby verified technicians) and targeted direct hiring (booking a specific professional "
    "based on verified ratings, badges, and work history). WorkBridge incorporates live GPS tracking via OpenStreetMap to visualize "
    "technician arrival, secure multi-channel payments, and comprehensive rating reviews. Furthermore, the system introduces WorkBridge Flex "
    "(a recurring credit-based loyalty membership featuring a 50% carry-forward benefit upon renewal), WorkBridge Share (allowing members "
    "to share services with family at another address), and WorkBridge Safe (an interactive press-and-hold SOS safety protocol for emergency escalation)."
)
add_justified_para(
    "The platform is architected around three primary user roles: Customer, Service Provider (Karigar), and Administrator. Customers book "
    "and track services; professionals manage incoming gig alerts, update live transit locations, and track earnings; while administrators "
    "manage trade catalogs, verify technician KYC documentation, and oversee safety incident records through a dedicated administrative data console."
)
add_justified_para(
    "The backend is powered by Google Firebase, providing flexible, scalable, and reactive data storage through Cloud Firestore and "
    "Realtime Database. The frontend developed using Flutter ensures high-performance cross-platform execution, fluid animations, and consistent usability."
)
add_justified_para(
    "Overall, the WorkBridge system enhances efficiency, safety, transparency, and convenience in local service commerce, creating a sustainable "
    "digital ecosystem that empowers skilled blue-collar workers while delivering guaranteed quality to consumers."
)

doc.add_page_break()

# -------------------------------------------------------------
# CHAPTER 1: INTRODUCTION
# -------------------------------------------------------------
add_chapter_title("1  INTRODUCTION")
add_section_title("1.1  PROJECT SUMMARY")
add_justified_para(
    "WorkBridge is a cross-platform, on-demand service marketplace application designed to modernize and bridge the divide "
    "between domestic households and skilled local technicians (Karigars). In contemporary urban and semi-urban communities, finding "
    "dependable, certified, and fairly priced technicians for urgent household tasks—such as burst water pipes, electrical short circuits, "
    "furniture damage, or appliance breakdowns—remains a frustrating, disorganized, and time-consuming chore. WorkBridge resolves this "
    "systemic market failure by delivering a centralized, reliable digital platform where customers can browse service categories, "
    "evaluate technician profiles, book on-demand repairs, make cashless payments, and track execution in real time."
)
add_justified_para(
    "The mobile system is constructed using Google’s Flutter framework with the Dart programming language, delivering high-speed native UI "
    "rendering across Android and iOS platforms from a single clean codebase. The backend is powered by Google Firebase, integrating Cloud Firestore "
    "for flexible NoSQL document management, Firebase Authentication for secure role-based identity validation, Firebase Realtime Database for "
    "low-latency GPS tracking synchronization, and Cloud Messaging for instant push dispatch alerts."
)
add_justified_para(
    "WorkBridge incorporates industry-leading specialized features designed for real-world reliability. It offers dual dispatch modes: "
    "Broadcast Requests (alerting all nearby certified Karigars for rapid emergency dispatch) and Specific Karigar Selection (allowing "
    "direct booking of preferred professionals). To safeguard consumers during in-home technician visits, the platform incorporates WorkBridge Safe, "
    "a dedicated emergency safety mechanism featuring an interactive press-and-hold SOS alert that connects to emergency response, alerts "
    "trusted family contacts, and provides live technician location context."
)
add_justified_para(
    "Additionally, the system introduces WorkBridge Flex, a customer loyalty membership offering recurring service credits with an innovative "
    "50% renewal carry-forward policy, as well as WorkBridge Share to extend service credits to relatives living at different addresses. Administrative "
    "operations are governed through an integrated Admin Data Hub that provides end-to-end control over customer accounts, technician KYC "
    "verification, trade categories, pricing, and financial analytics."
)

doc.add_page_break()

# 1.2 PURPOSE
add_section_title("1.2  PURPOSE")
add_justified_para(
    "The purpose of WorkBridge is to provide a reliable, efficient, and transparent digital marketplace that revolutionizes how home and local "
    "services are discovered, booked, and executed. The traditional service ecosystem suffers from extreme fragmentation, arbitrary pricing, "
    "unverified worker backgrounds, and erratic scheduling. WorkBridge modernizes this unorganized sector by providing an intuitive mobile platform "
    "that connects consumers with vetted, background-verified professionals in minutes."
)
add_justified_para(
    "The system enables service providers (Karigars) to build a credible digital identity, break free from exploitative local contractor cartels, "
    "receive steady direct job requests, and earn higher, predictable incomes. At the same time, platform administrators can monitor service quality, "
    "verify professional credentials, manage trade catalogs, and maintain high standards of trust, accountability, and customer satisfaction."
)

p_des = doc.add_paragraph()
p_des.add_run("This project is designed to:").font.bold = True
add_bullet_point("", "Reduce manual effort and delays by automating technician discovery, booking dispatch, and fulfillment tracking.")
add_bullet_point("", "Provide a smooth, responsive, and user-friendly mobile interface for exploring on-demand trade categories.")
add_bullet_point("", "Enable real-time geolocation tracking using interactive maps to display technician arrival and travel progress.")
add_bullet_point("", "Guarantee price transparency with upfront standardized estimates, cashless online payments (Razorpay), cash on delivery, and membership credit options.")
add_bullet_point("", "Empower skilled blue-collar professionals with dignified digital profiles, ratings, and instant job allocation.")
add_bullet_point("", "Protect user safety during active in-home service visits through the integrated WorkBridge Safe emergency SOS protocol.")
add_bullet_point("", "Foster customer retention and repeat usage through WorkBridge Flex membership credits and family service sharing.")
add_bullet_point("", "Provide administrators with robust oversight tools for technician KYC document verification, catalog management, and audit reporting.")

add_justified_para(
    "Overall, the purpose of this project is to deliver a secure, scalable, and equitable service ecosystem that uplifts local artisans while "
    "giving homeowners dependable, fast, and high-quality maintenance services."
)

doc.add_page_break()

# 1.3 TECHNOLOGY
add_section_title("1.3  TECHNOLOGY: FLUTTER, DART, FIREBASE")
add_justified_para(
    "The development of WorkBridge is grounded in modern cross-platform mobile architecture and reactive cloud services. Flutter, Google’s open-source "
    "UI software development kit, serves as the primary frontend framework. Flutter enables the development of natively compiled, high-performance "
    "applications for Android and iOS from a single Dart codebase. It provides smooth 60fps animations, rich material design widgets, responsive layouts, "
    "and rapid development capabilities."
)
add_justified_para(
    "Dart is the core object-oriented programming language powering the application logic. Dart offers strong typing, sound null-safety, and asynchronous "
    "event loops (Futures and Streams) that are vital for real-time mobile tasks such as continuous GPS location listening, Firestore stream subscriptions, "
    "and network request handling. State management across the application is engineered using the Provider pattern, ensuring predictable data flow, "
    "reactive widget rebuilding, and separation of UI components from business logic."
)
add_justified_para(
    "Google Firebase serves as the scalable serverless backend platform for WorkBridge. Cloud Firestore, a high-performance NoSQL document database, "
    "stores and synchronizes domain collections including users, service categories, booking requests, ratings, and payment logs. Firestore’s real-time "
    "listeners enable instant UI synchronization across client devices. Firebase Authentication handles secure user identity validation with email/password "
    "and phone OTP support, while Firebase Realtime Database provides ultra-low latency coordinate streaming for live technician map tracking."
)
add_justified_para(
    "Mapping and location services are implemented using the Geolocator and Flutter Map (OpenStreetMap / Leaflet) packages, allowing precise GPS position "
    "acquisition, address reverse geocoding, and interactive route visualization without incurring prohibitive commercial map licensing costs."
)
add_justified_para(
    "Overall, Flutter, Dart, and Firebase form an exceptionally robust, modern, and scalable technology stack that ensures WorkBridge delivers high responsiveness, "
    "cross-platform compatibility, and resilient real-time cloud data handling."
)

doc.add_page_break()

# -------------------------------------------------------------
# CHAPTER 2: PROJECT MANAGEMENT
# -------------------------------------------------------------
add_chapter_title("2  PROJECT MANAGEMENT")
add_section_title("2.1  PROJECT PLANNING AND SCHEDULING")
add_justified_para(
    "Project planning and scheduling for WorkBridge were structured to ensure disciplined execution, technical rigor, and timely delivery of an enterprise-grade "
    "mobile platform. Because WorkBridge involves a complex, three-sided marketplace—encompassing homeowners, skilled blue-collar workers, and platform "
    "administrators—the project scope was divided into distinct, manageable phases with clearly defined milestones, deliverables, and quality criteria."
)
add_justified_para(
    "The Planning Phase began with exhaustive requirement elicitation and field domain research. This involved analyzing traditional home maintenance pain "
    "points, technician availability challenges, pricing opacity, and safety risks during in-home visits. Functional specifications were established for core "
    "system modules, including multi-role authentication, trade category catalogs, dual booking dispatch algorithms (broadcast vs specific hiring), live map "
    "tracking, payment reconciliation, and safety escalation channels."
)
add_justified_para(
    "The Design Phase focused on creating the system architecture, component hierarchies, wireframe prototypes, and the Cloud Firestore NoSQL schema. "
    "Security rules and role access boundaries were drafted to ensure complete data isolation between customer and provider accounts. During the Development Phase, "
    "modular programming was conducted in Flutter and Dart, implementing state providers, repository layers, and reactive Firebase cloud services."
)
add_justified_para(
    "Scheduling was allocated across sequential two-week sprint intervals covering frontend design, backend integration, geolocation testing, bug fixing, "
    "and optimization. Continuous validation helped identify edge cases early—such as GPS signal drops or offline provider status—ensuring system stability before final academic submission."
)
add_justified_para(
    "Proper planning and disciplined scheduling enabled the successful completion of the WorkBridge platform within the stipulated university timeframe, "
    "resulting in a cohesive, reliable, and thoroughly verified software solution."
)

doc.add_page_break()

# 2.1.1 APPROACH
add_subsection_title("2.1.1  PROJECT DEVELOPMENT APPROACH")
add_justified_para(
    "The engineering of WorkBridge followed an Agile Iterative Development Approach tailored for modern on-demand service platforms. The project was executed "
    "through iterative cycles comprising requirement refinement, architectural modeling, rapid prototyping, feature implementation, and rigorous cross-platform "
    "testing. This methodology provided the flexibility needed to evolve system behavior based on practical testing feedback while maintaining structural clarity."
)
add_justified_para(
    "In the initial iteration, foundational requirements were prioritized, establishing user data models (Customer, Provider, Admin) and implementing multi-role "
    "authentication via Firebase Auth. Once identity validation was proven stable, subsequent iterations focused on the customer experience—building service "
    "category browsers, technician profile viewers, and booking request dispatchers."
)
add_justified_para(
    "The third iteration concentrated on the provider and tracking subsystems. Real-time background listeners were integrated to alert technicians of incoming jobs, "
    "while the Geolocator and Flutter Map engines were connected to stream live coordinates between moving technicians and the customer’s tracking view. A concurrent "
    "iteration implemented the administrative data console, enabling supervisors to verify technician credentials, inspect active bookings, and moderate reviews."
)
add_justified_para(
    "In the final iterations, proprietary specialized mechanisms were integrated and verified: WorkBridge Safe (the press-and-hold SOS safety protocol) and WorkBridge Flex "
    "(the credit-based loyalty subscription with 50% rollover rules). Automated unit tests, widget tests, and simulated field runs were executed at every stage to detect "
    "and eliminate race conditions or validation flaws."
)
add_justified_para(
    "This structured development approach ensured that the WorkBridge platform is highly maintainable, resilient under variable network conditions, and capable "
    "of satisfying real-world commercial and academic requirements effectively."
)

doc.add_page_break()

# 2.1.2 PLAN
add_subsection_title("2.1.2  PROJECT PLAN")
add_justified_para(
    "The project plan for WorkBridge defines the systematic breakdown of tasks, resource distributions, and logical activity sequences required to complete the "
    "platform within the allocated academic schedule. Tasks were structured to avoid implementation bottlenecks and guarantee smooth transitions between architectural "
    "design, coding, integration, and verification."
)
p_pl = doc.add_paragraph()
p_pl.add_run("The project plan incorporates the following seven primary activities:").font.bold = True
add_bullet_point("1. Requirement Collection and Analysis: ", "Conducting market analysis of local home services, interviewing consumers and trade professionals, identifying workflow requirements, and establishing formal software requirement specifications (SRS) for customer, provider, and admin roles.")
add_bullet_point("2. System Architecture and UI/UX Design: ", "Designing application navigational wireframes, high-fidelity Flutter widget hierarchies, Cloud Firestore database schemas, security rules, and formal UML/DFD design diagrams.")
add_bullet_point("3. Mobile Frontend Development: ", "Coding the customer and provider interfaces in Flutter, including splash, onboarding, category grids, service request modals, provider dashboards, and profile management screens.")
add_bullet_point("4. Cloud Backend & Firebase Integration: ", "Integrating Firebase Authentication, Cloud Firestore real-time streams, Cloud Messaging push alerts, and backend repository controllers for booking lifecycles and payment processing.")
add_bullet_point("5. Geolocation Engine & Live Tracking: ", "Implementing Geolocator GPS tracking, OpenStreetMap tile rendering, dynamic route calculation, and real-time technician-to-customer coordinate streaming.")
add_bullet_point("6. Quality Assurance, Testing and Debugging: ", "Conducting black-box functional testing, white-box logic validation, integration verification across cloud services, edge-case simulation, and performance profiling.")
add_bullet_point("7. Documentation and Academic Submission: ", "Authoring the comprehensive project report, capturing screen documentation, validating UML diagrams, and compiling project deliverables for formal degree evaluation.")

doc.add_page_break()

# 2.1.3 SCHEDULE
add_subsection_title("2.1.3  Schedule Representation")
add_justified_para(
    "The schedule representation of the WorkBridge project defines the project timeline, milestones, and chronological workflow required for successful software "
    "deployment. It establishes an organized roadmap that enabled systematic task tracking, efficient dependency management, and timely delivery of complex multi-stakeholder features."
)
add_justified_para(
    "In the WorkBridge project, the schedule was divided into sequential development milestones spanning requirement analysis, UI prototyping, core Flutter coding, "
    "cloud backend integration, specialized feature development (WorkBridge Flex & Safe), and comprehensive system testing. Each phase was assigned specific durations "
    "based on technical complexity and risk factors."
)

sched_table_data = [
    ("Phase / Activity", "Key Deliverables", "Allocated Time", "Status"),
    ("Phase 1: Requirement Analysis", "SRS Document, Use Cases & Market Research", "Week 1 – Week 2", "Completed"),
    ("Phase 2: UI/UX & Architecture", "Figma Mockups, Schema Design & UML", "Week 3 – Week 4", "Completed"),
    ("Phase 3: Core App Development", "Flutter UI Views, State Providers & Auth", "Week 5 – Week 8", "Completed"),
    ("Phase 4: Cloud & Location Engine", "Firestore Sync, Live GPS Map & Push Alerts", "Week 9 – Week 11", "Completed"),
    ("Phase 5: Flex, Safe & Admin", "WorkBridge Flex, SOS Protocol & Admin Hub", "Week 12 – Week 13", "Completed"),
    ("Phase 6: Testing & Final Report", "Test Cases, UAT, Documentation & PDF", "Week 14 – Week 16", "Completed"),
]

tbl_sched = doc.add_table(rows=len(sched_table_data), cols=4)
tbl_sched.alignment = WD_TABLE_ALIGNMENT.CENTER
for r_idx, row in enumerate(sched_table_data):
    for c_idx, val in enumerate(row):
        cell = tbl_sched.rows[r_idx].cells[c_idx]
        cell.paragraphs[0].text = val
        if r_idx == 0:
            cell.paragraphs[0].runs[0].font.bold = True

add_justified_para(
    "By strictly adhering to this schedule representation, the development of the WorkBridge system proceeded in an orderly and predictable manner, "
    "ensuring high architectural quality and on-time academic project delivery."
)

doc.add_page_break()

# -------------------------------------------------------------
# CHAPTER 3: SYSTEM REQUIREMENTS STUDY
# -------------------------------------------------------------
add_chapter_title("3  SYSTEM REQUIREMENTS STUDY")
add_section_title("3.1  USER CHARACTERISTICS")
add_justified_para(
    "The WorkBridge marketplace is designed to accommodate three distinct user classes: Customers (Homeowners), Service Providers (Karigars / Professionals), "
    "and the Platform Administrator. Each user group exhibits unique operational responsibilities, technical literacy levels, and system access permissions."
)

p_u1 = doc.add_paragraph()
p_u1.add_run("1. Customers (Homeowners / Clients):").font.bold = True
add_justified_para(
    "Customers are general domestic consumers who use the application to discover, schedule, and pay for household maintenance services. They possess standard "
    "familiarity with consumer mobile apps and smartphones. Customers can register, verify identity via OTP, browse trade catalogs (Plumbing, Electrical, Carpentry, etc.), "
    "filter technicians, select dispatch methods (Broadcast or Specific), track technician arrival via live GPS map, execute payments, manage WorkBridge Flex credits, "
    "trigger emergency SOS alerts via WorkBridge Safe, and submit star ratings and textual reviews. No technical expertise is required; the UI is designed to be "
    "self-explanatory, clean, and accessible."
)

p_u2 = doc.add_paragraph()
p_u2.add_run("2. Service Providers (Karigars / Skilled Professionals):").font.bold = True
add_justified_para(
    "Service Providers are skilled blue-collar artisans and technicians. They may possess basic or moderate digital literacy. WorkBridge provides an ultra-streamlined, "
    "high-contrast interface designed for quick one-tap actions. Providers can register, upload KYC identity documents for verification, manage trade specializations, "
    "review incoming job request cards, accept or decline gigs within a timeout countdown, update live transit locations, change execution states (Arrived, In-Progress, Completed), "
    "view accrued daily/weekly earnings, and inspect customer feedback ratings."
)

p_u3 = doc.add_paragraph()
p_u3.add_run("3. System Administrator:").font.bold = True
add_justified_para(
    "The administrator is a high-privilege technical supervisor responsible for overall platform governance. The admin manages customer and provider records, audits "
    "submitted KYC documents to approve or suspend Karigars, maintains the service category catalog, monitors real-time active bookings, reviews emergency incident logs "
    "generated by WorkBridge Safe, audits platform commission payouts, and analyzes operational revenue reports."
)

doc.add_page_break()

# 3.2 REQUIREMENTS
add_section_title("3.2  HARDWARE AND SOFTWARE REQUIREMENTS")
add_justified_para(
    "The WorkBridge system requires specific hardware and software components to ensure smooth development, cross-platform compilation, database scalability, "
    "and reliable end-user mobile execution."
)

p_hr = doc.add_paragraph()
p_hr.add_run("Hardware Requirements:").font.bold = True
add_bullet_point("Processor: ", "Intel Core i5 / i7 or AMD Ryzen 5 / 7 (Multi-core, 2.5 GHz or higher).")
add_bullet_point("RAM: ", "Minimum 8 GB (16 GB strongly recommended for smooth Android Studio emulator execution).")
add_bullet_point("Storage: ", "Minimum 20 GB free disk space (Solid State Drive SSD recommended for fast Flutter builds).")
add_bullet_point("Development Workstation: ", "Laptop or Desktop PC running modern 64-bit OS.")
add_bullet_point("Mobile Testing Devices: ", "Physical Android smartphone (Android OS 9.0 Pie or higher, GPS and internet enabled) and/or iOS device (iOS 13.0+).")
add_bullet_point("Network Connection: ", "High-speed broadband / 4G / 5G internet for real-time Firebase cloud sync and map tile streaming.")

p_sr = doc.add_paragraph()
p_sr.add_run("Software Requirements:").font.bold = True
add_bullet_point("Operating System: ", "Windows 10/11 (64-bit), macOS, or Linux.")
add_bullet_point("Development IDE: ", "Visual Studio Code and/or Android Studio with Flutter & Dart plugins.")
add_bullet_point("SDK: ", "Flutter SDK (v3.24+ / 3.9.2), Dart SDK (v3.5+).")
add_bullet_point("State Management: ", "Provider Package (v6.1.2) for reactive architectural state separation.")
add_bullet_point("Cloud Backend: ", "Google Firebase (Firebase Core, Firebase Auth, Cloud Firestore, Realtime Database, Cloud Messaging, Cloud Storage).")
add_bullet_point("Mapping & GPS: ", "Geolocator (v14.0+), Latlong2, and Flutter Map (v8.3+) utilizing OpenStreetMap tiles.")
add_bullet_point("Payment Processing: ", "Razorpay Gateway SDK / Integration utilities.")
add_bullet_point("Version Control: ", "Git and GitHub for collaborative source control and tracking.")

doc.add_page_break()

# -------------------------------------------------------------
# CHAPTER 4: SYSTEM ANALYSIS
# -------------------------------------------------------------
add_chapter_title("4  SYSTEM ANALYSIS")
add_section_title("4.1  STUDY OF CURRENT SYSTEM")
add_justified_para(
    "In the conventional home services market, finding skilled labor—such as a licensed plumber, certified electrician, carpenter, or appliance repair technician—relies "
    "heavily on informal, word-of-mouth recommendations, neighborhood hardware store inquiries, or unverified phone directories. This traditional approach is plagued by "
    "severe friction, unpredictability, and total lack of standardization."
)
add_justified_para(
    "When an emergency household fault occurs—such as a ruptured water pipe or electrical short-circuit—homeowners are forced to make numerous phone calls to independent "
    "technicians whose current availability, geographical distance, and pricing rates are completely unknown. In many cases, technicians do not answer, arrive hours late, "
    "or fail to show up altogether. Furthermore, because pricing is negotiated informally without standard rate cards, consumers are routinely subjected to arbitrary overcharging, "
    "unexpected hidden fees, and inflated replacement parts costs."
)
add_justified_para(
    "Safety and background verification represent another critical vulnerability in the existing system. Allowing unverified, anonymous workers into private residential spaces "
    "poses substantial security risks for homeowners, particularly women, children, and elderly individuals. Traditional methods provide zero background checks, no government "
    "ID verification, and no recourse or institutional accountability if shoddy work causes structural property damage."
)
add_justified_para(
    "Conversely, skilled technicians (Karigars) also suffer under the traditional model. They lack dependable marketing channels and are frequently exploited by local contractors "
    "who take large cuts of their earnings. Technicians endure irregular gig flow, delayed cash payments, and have no platform to accumulate a verified professional reputation."
)
add_justified_para(
    "These profound limitations underscore the urgent necessity for a modern, digital on-demand solution. WorkBridge addresses these systemic failures by delivering a structured, "
    "mobile-first marketplace that brings transparency, instant dispatch, verified accountability, and automated safety to domestic maintenance commerce."
)

doc.add_page_break()

# 4.2 PROBLEM AND WEAKNESSES
add_section_title("4.2  PROBLEM AND WEAKNESSES OF CURRENT SYSTEM")
add_justified_para(
    "A comprehensive analysis of the existing informal local service ecosystem reveals deep-seated operational, financial, and security problems across all participant groups:"
)

p_w1 = doc.add_paragraph()
p_w1.add_run("For Customers (Homeowners):").font.bold = True
add_bullet_point("", "High search friction and lost time attempting to locate nearby available technicians.")
add_bullet_point("", "Unpredictable response times with frequent no-shows during urgent emergencies.")
add_bullet_point("", "Opaque and arbitrary pricing with no standardized upfront rate cards or digital receipts.")
add_bullet_point("", "Significant safety and security concerns regarding unverified workers inside private homes.")
add_bullet_point("", "Zero recourse, warranty, or formal dispute escalation if services are executed improperly.")
add_bullet_point("", "Absence of digital service history, itemized billing, or loyalty benefits.")

p_w2 = doc.add_paragraph()
p_w2.add_run("For Service Providers (Karigars / Technicians):").font.bold = True
add_bullet_point("", "Erratic, unpredictable work pipelines resulting in substantial income instability.")
add_bullet_point("", "Heavy dependency on predatory local contractors and middlemen who extract exorbitant commissions.")
add_bullet_point("", "Delayed cash payments and disputes over agreed-upon labor fees.")
add_bullet_point("", "Inability to showcase verified craftsmanship, skills, certifications, and customer reviews.")
add_bullet_point("", "Inefficient travel across distant neighborhoods due to lack of localized routing tools.")

p_w3 = doc.add_paragraph()
p_w3.add_run("System-Level Weaknesses:").font.bold = True
add_bullet_point("", "Total absence of a centralized digital directory of authenticated, KYC-verified trade professionals.")
add_bullet_point("", "No real-time GPS tracking or route visualization for technician transit.")
add_bullet_point("", "Complete lack of emergency safety mechanisms during active residential service calls.")
add_bullet_point("", "Inability to generate macroeconomic labor analytics, tax audit trails, or industry trend metrics.")
add_bullet_point("", "High market fragmentation preventing scalability and service quality standardization.")

doc.add_page_break()

# 4.3 FEASIBILITY STUDY
add_section_title("4.3  FEASIBILITY STUDY")
add_justified_para(
    "The feasibility study for the WorkBridge system evaluates the practical viability, technical capability, financial sustainability, and operational readiness of the platform."
)

p_f1 = doc.add_paragraph()
p_f1.add_run("1. Technical Feasibility: ").font.bold = True
p_f1.add_run(
    "WorkBridge is technically feasible as it leverages Google’s established Flutter UI framework and Firebase cloud backend. These open-source and serverless "
    "technologies are widely adopted, fully documented, and engineered for high concurrency. Flutter delivers compile-time native speed across Android and iOS, while Cloud Firestore "
    "and Realtime Database provide horizontal cloud scalability. Geolocation tracking is accomplished efficiently using open-source OpenStreetMap tiles and the device GPS, "
    "avoiding restrictive third-party API dependencies."
)

p_f2 = doc.add_paragraph()
p_f2.add_run("2. Operational Feasibility: ").font.bold = True
p_f2.add_run(
    "The platform is operationally feasible because it is specifically tailored to the real-world behaviors of its users. Customers interact with a modern, consumer-grade shopping "
    "interface with minimal onboarding barriers. For Karigars, the interface utilizes bold icons, audio-visual job alerts, and one-tap accept/reject mechanisms that accommodate varying "
    "levels of digital literacy. Administrators gain a centralized dashboard that automates verification, dispatch, and safety oversight without requiring extensive staff."
)

p_f3 = doc.add_paragraph()
p_f3.add_run("3. Economic Feasibility: ").font.bold = True
p_f3.add_run(
    "The development of WorkBridge is cost-effective because it utilizes open-source development tools (VS Code, Flutter SDK, Dart) and Firebase’s free/low-cost development tier. "
    "In production, the system generates diversified revenues through a sustainable two-sided business model: service commissions from completed gigs, recurring WorkBridge Flex memberships, "
    "optional featured listings for top Karigars, and platform convenience fees."
)

p_f4 = doc.add_paragraph()
p_f4.add_run("4. Schedule Feasibility: ").font.bold = True
p_f4.add_run(
    "By organizing tasks into six disciplined agile phases and leveraging Flutter’s rapid widget prototyping, all design, development, testing, and documentation activities were completed "
    "strictly within university academic milestone deadlines."
)

doc.add_page_break()

# 4.4 REQUIREMENTS VALIDATION
add_section_title("4.4  REQUIREMENTS VALIDATION")
add_justified_para(
    "The Requirements Validation process for WorkBridge ensures that all identified functional and non-functional requirements are technically accurate, mutually consistent, and fully "
    "aligned with the expectations of customers, technicians, and administrators. This validation guarantees that the software addresses real-world operational challenges rather than hypothetical assumptions."
)
add_justified_para(
    "In the WorkBridge project, requirements were validated through systematic reviews of real user workflows:"
)
add_bullet_point("Role Authentication & Permissions: ", "Ensuring strict isolation between Customer, Service Provider, and Admin accounts so that providers cannot access customer booking creation APIs and customers cannot accept gig requests.")
add_bullet_point("Dual Dispatch Engine Validation: ", "Validating that Broadcast Requests properly fan out to all active technicians registered under the chosen trade category within a geographic radius, while Specific Karigar Requests route exclusively to the targeted professional.")
add_bullet_point("Geolocation & Real-Time Tracking: ", "Verifying that technician GPS updates synchronize reliably to Cloud Firestore and Realtime Database, calculating accurate ETAs and visualizing route paths on OpenStreetMap without excessive battery drain.")
add_bullet_point("WorkBridge Safe Emergency Response: ", "Thoroughly verifying that the press-and-hold SOS button cannot be triggered accidentally, automatically dials emergency services, pushes SMS/notifications with coordinates to trusted contacts, and flags active incidents on the Admin Console.")
add_bullet_point("WorkBridge Flex Ledger Integrity: ", "Verifying credit allocation (10/month), usage deduction upon service completion, and proper calculation of the 50% rollover rule at membership renewal.")
add_bullet_point("Payment Reconciliation: ", "Testing Razorpay webhook callbacks to ensure transaction status matches booking state transitions.")

add_justified_para(
    "Overall, the validation process confirmed that WorkBridge is functionally comprehensive, secure, and fully prepared for reliable live implementation."
)

doc.add_page_break()

# 4.5 FUNCTIONS OF SYSTEM & 4.5.1 ER DIAGRAM
add_chapter_title("4.5  FUNCTIONS OF SYSTEM")
add_section_title("4.5.1  ER Diagram")
add_justified_para(
    "The Entity-Relationship (ER) diagram models the logical schema of the WorkBridge marketplace. It defines the core domain entities—Users, Categories, "
    "Service Requests, Payments, Reviews, Flex Memberships, Safety Incidents, and Locations—along with their primary keys (PK), foreign keys (FK), and cardinality relationships."
)

er_png = os.path.join(DIAGRAMS_DIR, "er_diagram.png")
if os.path.exists(er_png):
    p_img = doc.add_paragraph()
    p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_img.add_run().add_picture(er_png, width=Inches(6.2))

doc.add_page_break()

# 4.5.2 USE CASE DIAGRAM
add_section_title("4.5.2  User Case Diagram")
add_justified_para(
    "The Use Case diagram illustrates the behavioral interactions between the system actors (Customer, Service Provider/Karigar, and Administrator) and the platform use cases, "
    "detailing «include» and «extend» relationships."
)

uc_png = os.path.join(DIAGRAMS_DIR, "usecase_diagram.png")
if os.path.exists(uc_png):
    p_img = doc.add_paragraph()
    p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_img.add_run().add_picture(uc_png, width=Inches(6.2))

doc.add_page_break()

# 4.5.3 DFD
add_section_title("4.5.3  Data Flow Diagram (0 and 1 level)")
add_justified_para(
    "The Data Flow Diagram illustrates the logical flow of information through the WorkBridge architecture, detailing both the high-level Level 0 Context Diagram and "
    "the decomposed Level 1 process and data store interactions."
)

dfd_png = os.path.join(DIAGRAMS_DIR, "dfd_diagram.png")
if os.path.exists(dfd_png):
    p_img = doc.add_paragraph()
    p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_img.add_run().add_picture(dfd_png, width=Inches(6.2))

doc.add_page_break()

# 4.6 DATA MODELING
add_section_title("4.6  DATA MODELING")
add_justified_para(
    "Data modeling for the WorkBridge system defines how application entities, business transactions, and real-time states are structured and stored within Cloud Firestore, "
    "a scalable NoSQL cloud document database. Documents are organized into modular collections, supporting rapid reactive streaming and atomic data operations."
)
p_col = doc.add_paragraph()
p_col.add_run("The primary collections used in the WorkBridge system are:").font.bold = True
add_bullet_point("users: ", "Stores unified user identity records including UID, full name, email, phone number, hashed password, canonical system role (customer, service_provider, admin), verification badge status (isVerified), assigned trade categories, and creation timestamps.")
add_bullet_point("service_categories: ", "Defines the 8 canonical service trade categories (Plumbing, Electrical, Carpentry, Painting, Cleaning, Appliance Repair, Salon & Beauty, Vehicle Services) with icon identifiers, accent colors, active status, and provider counts.")
add_bullet_point("service_requests: ", "Manages service bookings, capturing customer ID, category ID, title, description, estimated price, scheduled date and time, dispatch type (broadcast vs specific), target provider ID, assigned provider ID, execution status (pending, accepted, in_progress, completed, cancelled), and customer GPS coordinates.")
add_bullet_point("ratings_reviews: ", "Stores verified customer ratings (1 to 5 stars), textual comments, booking references, and technician associations.")
add_bullet_point("payments: ", "Records platform financial transactions, payment method (Online / Razorpay, Cash on Delivery, Flex Credit), transaction reference, amount, and settlement status.")
add_bullet_point("flex_memberships: ", "Tracks customer loyalty subscriptions, monthly credit quotas (10 credits/month, 120/year), consumed credits, remaining credits, and 50% rollover rules upon renewal.")
add_bullet_point("safety_incidents: ", "Logs WorkBridge Safe emergency SOS events, including booking ID, triggering user, incident coordinates, emergency contact phone numbers, and resolution audit logs.")
add_bullet_point("provider_locations: ", "Streams real-time GPS coordinate breadcrumbs (latitude, longitude, speed, timestamp) for active en-route technicians.")
add_bullet_point("app_settings: ", "Contains system configuration parameters, commission fee rates, customer support contacts, and version control metadata.")

add_justified_para(
    "The relationships between these collections maintain referential integrity through foreign keys, ensuring efficient querying, real-time sync, "
    "and robust data consistency across the ecosystem."
)

doc.add_page_break()

# 4.7 MAIN MODULES
add_section_title("4.7  MAIN MODULES OF NEW SYSTEM")
add_justified_para(
    "The WorkBridge platform is architected into three specialized, interconnected modules: Customer Module, Professional (Karigar) Module, and Admin Module. "
    "Each module is optimized for its respective user persona to ensure seamless, intuitive operation."
)

p_m1 = doc.add_paragraph()
p_m1.add_run("1. Customer Module:").font.bold = True
add_bullet_point("User Registration & Authentication: ", "Secure onboarding with email, password, and phone OTP verification.")
add_bullet_point("Category Catalog & Search: ", "Instant exploration of 8 trade categories with detailed task descriptions and price ranges.")
add_bullet_point("Flexible Booking Engine: ", "Option to choose between Broadcast Requests (rapid local alert) or Specific Karigar Selection.")
add_bullet_point("Live Geolocation Tracking: ", "Interactive OpenStreetMap showing the assigned technician’s real-time transit and arrival ETA.")
add_bullet_point("WorkBridge Safe (SOS): ", "Press-and-hold emergency safety trigger alerting police, trusted contacts, and platform support.")
add_bullet_point("WorkBridge Flex & Share: ", "Credit-based loyalty membership management with 50% renewal rollover and family sharing.")
add_bullet_point("Payments & Digital Invoicing: ", "Razorpay gateway, cash on delivery, and instant itemized digital invoice downloads.")
add_bullet_point("Ratings & Reviews: ", "Verified post-service feedback and star rating submission.")

p_m2 = doc.add_paragraph()
p_m2.add_run("2. Professional (Karigar) Module:").font.bold = True
add_bullet_point("KYC Registration: ", "Profile setup with government ID, trade certification, and photo upload for verification.")
add_bullet_point("Real-Time Job Alerts: ", "Audio-visual notification cards for incoming gig requests with 45-second accept/reject timers.")
add_bullet_point("Navigation & Status Control: ", "One-tap route directions and lifecycle status updates (Arrived, In-Progress, Completed).")
add_bullet_point("Earnings & Payouts: ", "Daily and weekly earnings ledger, commission breakdown, and bank payout requests.")
add_bullet_point("Reputation Portfolio: ", "Customer reviews, average rating score, and verified skill badges.")

p_m3 = doc.add_paragraph()
p_m3.add_run("3. Admin Module:").font.bold = True
add_bullet_point("Executive Dashboard: ", "High-level KPI metrics on platform revenue, active bookings, and technician density.")
add_bullet_point("Technician KYC Auditing: ", "Document review workflow to verify, approve, or reject Karigar registrations.")
add_bullet_point("Category & Catalog Control: ", "Dynamic Firestore management of services, trade descriptions, and base rates.")
add_bullet_point("Incident & Dispute Resolution: ", "Immediate safety escalation dashboard to manage WorkBridge Safe SOS alerts.")
add_bullet_point("Financial Analytics: ", "Commission tracking, payout audit logs, and downloadable monthly financial reports.")

doc.add_page_break()

# -------------------------------------------------------------
# CHAPTER 5: SYSTEM DESIGN & FLOW CHART
# -------------------------------------------------------------
add_chapter_title("5  SYSTEM DESIGN")
add_section_title("5.1  FLOW CHART")
add_justified_para(
    "The system Flowchart illustrates the end-to-end execution flow of WorkBridge, tracing the customer service request cycle, technician matching and "
    "live tracking flow, and administrative supervision."
)

fc_png = os.path.join(DIAGRAMS_DIR, "flowchart_diagram.png")
if os.path.exists(fc_png):
    p_img = doc.add_paragraph()
    p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_img.add_run().add_picture(fc_png, width=Inches(6.2))

doc.add_page_break()

# -------------------------------------------------------------
# CHAPTER 6: TESTING
# -------------------------------------------------------------
add_chapter_title("6  TESTING")
add_section_title("6.1  TEST PLAN")
add_justified_para(
    "The testing plan for WorkBridge defines the structured validation methodology employed to verify that every software component, user role, and cloud "
    "integration functions correctly and fulfills all specified software requirements. The objective of the testing plan is to identify defect conditions early, "
    "ensure data integrity across Cloud Firestore, and guarantee smooth performance before mobile deployment."
)
add_justified_para(
    "Because WorkBridge is a multi-stakeholder ecosystem with continuous background geolocation streaming, the testing plan spans multiple specialized testing domains: "
    "functional module testing, responsive UI testing, GPS map route validation, Firestore security rule enforcement, payment gateway verification, and user acceptance "
    "testing across both customers and blue-collar technicians."
)

p_tobj = doc.add_paragraph()
p_tobj.add_run("The main objectives of the testing plan are:").font.bold = True
add_bullet_point("", "To verify that customer booking workflows—both Broadcast and Specific Karigar requests—dispatch and allocate accurately.")
add_bullet_point("", "To validate that user authentication, role enforcement, and session management prevent unauthorized privilege escalation.")
add_bullet_point("", "To ensure that real-time geolocation streaming displays accurate technician positions and arrival estimates without application crashes.")
add_bullet_point("", "To verify that the WorkBridge Safe emergency SOS trigger operates with complete reliability under simulated emergency conditions.")
add_bullet_point("", "To confirm that WorkBridge Flex membership service credits, rollover carry-forward algorithms, and Razorpay transactions compute without ledger discrepancies.")
add_bullet_point("", "To validate that form validations reject malformed phone numbers, invalid emails, and empty fields with descriptive error notifications.")
add_bullet_point("", "To guarantee that the application remains responsive, fluid, and memory-efficient across standard mobile devices.")

doc.add_page_break()

# 6.2 TESTING STRATEGY
add_section_title("6.2  TESTING STRATEGY")
add_justified_para(
    "The testing strategy for WorkBridge outlines the techniques, tools, and validation environments used to evaluate the correctness, stability, and security of the system. "
    "A balanced combination of Black-Box Testing, White-Box Testing, and Integration Testing was utilized."
)

p_ts1 = doc.add_paragraph()
p_ts1.add_run("1. Black-Box Testing:").font.bold = True
add_justified_para(
    "Black-box testing focuses on validating functional behavior against the software requirement specifications without examining the underlying Dart source code. "
    "Testers supply inputs through the Flutter mobile UI and verify that expected outputs, navigation transitions, and database state updates occur correctly."
)
p_ts1_sub = doc.add_paragraph()
p_ts1_sub.add_run("This method was mainly used to test:").font.bold = True
add_bullet_point("", "User registration, login, password recovery, and role redirection (Customer vs Provider vs Admin).")
add_bullet_point("", "Trade category exploration, keyword searching, and technician filtering.")
add_bullet_point("", "Booking creation modals, date/time pickers, and address input validation.")
add_bullet_point("", "Payment gateway dialogs, UPI payment completion, and digital receipt generation.")
add_bullet_point("", "WorkBridge Safe interactive press-and-hold button behavior and emergency modal popups.")
add_bullet_point("", "Form error messaging when mandatory fields are omitted.")

p_ts2 = doc.add_paragraph()
p_ts2.add_run("2. White-Box Testing:").font.bold = True
add_justified_para(
    "White-box testing focuses on validating internal algorithmic logic, data structures, and code execution paths within Dart and Flutter. Developers analyze execution branching, "
    "error catch handlers, and Firestore transactions."
)
p_ts2_sub = doc.add_paragraph()
p_ts2_sub.add_run("Developers checked:").font.bold = True
add_bullet_point("", "Provider state management logic in user_controller.dart and booking state notifiers.")
add_bullet_point("", "Asynchronous Stream and Future error handling during network dropouts.")
add_bullet_point("", "Mathematical algorithms governing WorkBridge Flex 50% credit rollover calculations upon renewal.")
add_bullet_point("", "Firestore security rules verifying that non-admin users cannot modify the isVerified flag.")
add_bullet_point("", "Coordinate distance calculation algorithms determining nearby provider broadcast radiuses.")

doc.add_page_break()

# 6.2 CONTINUED
add_subsection_title("3. Integration Testing")
add_justified_para(
    "Integration testing verifies that different modular components of the WorkBridge platform function harmoniously when combined into a unified workflow. "
    "This ensures that cross-service dependencies operate without data loss or race conditions."
)
add_bullet_point("Flutter UI and Cloud Firestore Synchronization: ", "Testing that when a customer submits a service request, the Firestore document write immediately triggers the real-time stream listener on the Karigar’s device to pop up the job alert card.")
add_bullet_point("Geolocator and Flutter Map Integration: ", "Verifying that continuous location streams from the provider’s phone correctly update Realtime Database coordinates and render as a moving marker on the customer’s map.")
add_bullet_point("Razorpay Payment Gateway Integration: ", "Ensuring that successful payment webhooks update booking documents from in_progress to completed and record immutable payment transaction receipts.")
add_bullet_point("WorkBridge Safe Notification Pipeline: ", "Validating that triggering an SOS alert synchronously updates the incident database, dials emergency phone intents, and pushes alerts to the Admin Console.")

add_subsection_title("4. System Testing")
add_justified_para(
    "System testing evaluates the WorkBridge application as an end-to-end integrated whole under simulated production conditions. This includes testing system recovery "
    "after loss of internet connectivity, memory usage optimization during map navigation, battery consumption profiling, and multi-user concurrency testing."
)

add_subsection_title("5. User Acceptance Testing (UAT)")
add_justified_para(
    "User Acceptance Testing (UAT) was conducted by inviting actual homeowners and local technicians to test the application in real-world scenarios. Feedback confirmed "
    "that the dual booking modes, live map tracking, and simple one-tap job acceptance cards met practical expectations with high satisfaction."
)

doc.add_page_break()

# 6.3 TESTING METHODS
add_section_title("6.3  TESTING METHODS")
add_bullet_point("1. Black-Box Testing: ", "Operates independently of internal code visibility. Focuses on functional input/output behavior, user flows, and error handling.")
add_bullet_point("2. White-Box Testing: ", "Internal validation of Dart code paths, asynchronous streams, and business logic. Ensures optimized memory management, robust exception catching, and secure Firestore operations.")
add_bullet_point("3. Unit Testing: ", "Small, isolated Dart functions and model serializers are tested independently (UserModel, ServiceRequestModel, ServiceCategory, input regex validators).")
add_bullet_point("4. Integration Testing: ", "Tests interconnected subsystem communication, ensuring smooth reactive data flow between Customer, Provider, Admin, Firestore, and Payment Gateways.")
add_bullet_point("5. System Testing: ", "Comprehensive end-to-end evaluation of WorkBridge on physical mobile hardware, verifying cross-device UI responsiveness, GPS accuracy, battery efficiency, and error recovery.")
add_bullet_point("6. User Acceptance Testing (UAT): ", "Conducted with representative real-world participants (customers and technicians) to confirm operational usability, accessibility, intuitiveness, and overall user satisfaction.")

doc.add_page_break()

# 6.4 TEST CASES (Cases 1 to 5)
add_section_title("6.4  TEST CASES (Purpose, Required output, Expected Result)")

test_cases_1 = [
    ("Test Case 1: Customer Registration (Valid Credentials)",
     "To verify that a new customer can successfully register an account",
     "Valid Name, Email, Phone (+91 9876543210), and Password",
     "Account is created in Firebase Auth & Firestore; redirected to Home Dashboard"),
    ("Test Case 2: User Login (Invalid Password)",
     "To ensure that invalid login attempts are securely handled",
     "Correct Email with incorrect/mismatched password",
     "System rejects login and displays “Invalid email or password” error message"),
    ("Test Case 3: Registration Form Validation (Empty Fields)",
     "To verify that the registration form validates mandatory fields",
     "Form submitted with empty phone number or malformed email",
     "Submission blocked; field-specific validation warnings displayed in red"),
    ("Test Case 4: Service Booking Creation (Broadcast Request)",
     "To verify successful creation of an on-demand broadcast service request",
     "Category: Plumbing, Title, Address, Schedule Date/Time, Mode: Broadcast",
     "Booking document created with status pending; dispatched to local plumbers"),
    ("Test Case 5: Direct Karigar Booking (Specific Request)",
     "To verify direct targeted hiring of a specific service provider",
     "Target Provider UID (Ramesh Solanki), Task details, Date & Time",
     "Request assigned directly to target Karigar; status set to pending"),
]

for title, purpose, req_in, exp_res in test_cases_1:
    p_tc = doc.add_paragraph()
    p_tc.add_run(title).font.bold = True
    tbl = doc.add_table(rows=3, cols=2)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl.rows[0].cells[0].paragraphs[0].text = "Purpose"
    tbl.rows[0].cells[0].paragraphs[0].runs[0].font.bold = True
    tbl.rows[0].cells[1].paragraphs[0].text = purpose
    tbl.rows[1].cells[0].paragraphs[0].text = "Required Input"
    tbl.rows[1].cells[0].paragraphs[0].runs[0].font.bold = True
    tbl.rows[1].cells[1].paragraphs[0].text = req_in
    tbl.rows[2].cells[0].paragraphs[0].text = "Expected Result"
    tbl.rows[2].cells[0].paragraphs[0].runs[0].font.bold = True
    tbl.rows[2].cells[1].paragraphs[0].text = exp_res

doc.add_page_break()

# 6.4 TEST CASES (Cases 6 to 10)
test_cases_2 = [
    ("Test Case 6: Karigar Job Request Acceptance",
     "To verify that a Karigar can accept an incoming job alert",
     "Provider taps “Accept Job” button within the 45-second countdown timer",
     "Booking status updates to accepted; customer notified; route navigation opened"),
    ("Test Case 7: Real-Time Geolocation Tracking & Route Sync",
     "To verify live GPS coordinate streaming from provider to customer view",
     "Technician starts transit; location service streams GPS coordinates",
     "Customer map reflects technician marker movement and dynamic arrival ETA"),
    ("Test Case 8: WorkBridge Safe SOS Emergency Alert Trigger",
     "To ensure the emergency SOS safety protocol functions with high reliability",
     "Customer presses and holds SOS button for 3 continuous seconds",
     "Emergency dialer launched; SMS sent to trusted contact; incident logged in Admin Hub"),
    ("Test Case 9: WorkBridge Flex Credit Deduction & 50% Rollover",
     "To verify credit ledger updates and rollover calculation upon renewal",
     "Customer books via Flex Credit (10 remaining); membership cycle renews",
     "1 credit deducted; remaining 9 credits roll over at 50% (4.5 → 5 credits) into new cycle"),
    ("Test Case 10: Online Payment & Review Submission",
     "To verify payment completion and customer review storage",
     "Customer completes payment via Razorpay and submits 5-star rating with review",
     "Payment verified; booking set to completed; review added to provider profile"),
]

for title, purpose, req_in, exp_res in test_cases_2:
    p_tc = doc.add_paragraph()
    p_tc.add_run(title).font.bold = True
    tbl = doc.add_table(rows=3, cols=2)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl.rows[0].cells[0].paragraphs[0].text = "Purpose"
    tbl.rows[0].cells[0].paragraphs[0].runs[0].font.bold = True
    tbl.rows[0].cells[1].paragraphs[0].text = purpose
    tbl.rows[1].cells[0].paragraphs[0].text = "Required Input"
    tbl.rows[1].cells[0].paragraphs[0].runs[0].font.bold = True
    tbl.rows[1].cells[1].paragraphs[0].text = req_in
    tbl.rows[2].cells[0].paragraphs[0].text = "Expected Result"
    tbl.rows[2].cells[0].paragraphs[0].runs[0].font.bold = True
    tbl.rows[2].cells[1].paragraphs[0].text = exp_res

doc.add_page_break()

# -------------------------------------------------------------
# CHAPTER 7: SCREENSHOTS
# -------------------------------------------------------------
add_chapter_title("7  SCREENSHOTS")

# Screens metadata
screen_pages = [
    ("USER SIDE", "Home page", os.path.join(SCREENS_DIR, "screen_home.png"), 5.5),
    ("", "Login page & Register page", os.path.join(SCREENS_DIR, "screen_auth.png"), 6.2),
    ("", "Reset password page & OTP Verification", os.path.join(SCREENS_DIR, "screen_password.png"), 6.2),
    ("", "Service Categories page", os.path.join(SCREENS_DIR, "screen_catalog.png"), 5.5),
    ("", "Professional Details page", os.path.join(SCREENS_DIR, "screen_provider_details.png"), 5.5),
    ("", "Service Booking Modal (Broadcast vs Specific)", os.path.join(SCREENS_DIR, "screen_booking_modal.png"), 6.2),
    ("", "Checkout page & Online Payment (Razorpay)", os.path.join(SCREENS_DIR, "screen_checkout.png"), 6.2),
    ("", "Customer Profile page & Bookings list", os.path.join(SCREENS_DIR, "screen_profile.png"), 6.2),
    ("", "Booking Details & Status Lifecycle Timeline", os.path.join(SCREENS_DIR, "screen_lifecycle.png"), 5.5),
    ("", "Live Geolocation Tracking Map", os.path.join(SCREENS_DIR, "screen_tracking_map.png"), 5.5),
    ("", "WorkBridge Flex Membership (Service Credits)", os.path.join(SCREENS_DIR, "screen_flex.png"), 5.5),
    ("", "WorkBridge Safe (SOS Emergency Protocol)", os.path.join(SCREENS_DIR, "screen_safe.png"), 5.5),
    ("ADMIN SIDE", "Executive Dashboard page", os.path.join(SCREENS_DIR, "screen_admin_dashboard.png"), 6.2),
    ("", "Admin Data Management Screen (Data Hub)", os.path.join(SCREENS_DIR, "screen_admin_data.png"), 6.2),
    ("", "Booking Management & Live Gigs Oversight", os.path.join(SCREENS_DIR, "screen_admin_dashboard.png"), 6.2),
    ("", "User Management & Revenue Analytics", os.path.join(SCREENS_DIR, "screen_admin_data.png"), 6.2),
    ("PROFESSIONAL SIDE", "Karigar Console & Job Requests Acceptance", os.path.join(SCREENS_DIR, "screen_karigar.png"), 5.5),
]

for side, title, path, width_in in screen_pages:
    if side:
        p_side = doc.add_paragraph()
        p_side.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r_s = p_side.add_run(side)
        r_s.font.name = 'Times New Roman'
        r_s.font.size = Pt(14)
        r_s.font.bold = True
        r_s.font.underline = True

    p_t = doc.add_paragraph()
    p_t.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_t = p_t.add_run(title)
    r_t.font.name = 'Times New Roman'
    r_t.font.size = Pt(13)
    r_t.font.bold = True
    r_t.font.underline = True

    if os.path.exists(path):
        p_img = doc.add_paragraph()
        p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_img.add_run().add_picture(path, width=Inches(width_in))

    doc.add_page_break()

# -------------------------------------------------------------
# CHAPTER 8: LIMITATION AND FUTURE ENHANCEMENT
# -------------------------------------------------------------
add_chapter_title("8  LIMITATION AND FUTURE ENHANCEMENT")
add_section_title("Limitations")
add_bullet_point("Internet & Connectivity Dependency: ", "The application requires continuous smartphone cellular data or Wi-Fi to synchronize real-time Cloud Firestore updates and map tiles.")
add_bullet_point("GPS Signal Accuracy: ", "In dense high-rise apartment complexes or basement levels, satellite GPS attenuation may cause minor temporary fluctuations in technician location tracking.")
add_bullet_point("Third-Party Gateway Dependencies: ", "Online cashless payment processing depends on the external server uptime and network latency of the Razorpay payment infrastructure.")
add_bullet_point("Initial Technician Geographic Density: ", "In newly launched suburban territories, broadcast request fulfillment speed is influenced by the density of nearby onboarded Karigars.")
add_bullet_point("Battery Consumption During Continuous Tracking: ", "High-frequency GPS polling on low-tier technician smartphones may increase device battery drain over extended working shifts.")

add_section_title("Future Enhancements")
add_bullet_point("AI-Powered Safety Intelligence: ", "Integration of machine learning models to detect anomalies during active service visits (e.g. unexpected route deviations or abnormally prolonged job durations) to alert human safety teams preemptively.")
add_bullet_point("AI-Based Smart Matchmaking: ", "Machine learning algorithms that match customer service requests with technicians based on proximity, past review sentiment, and historic completion velocity.")
add_bullet_point("Multi-Lingual Voice Assistant: ", "Implementing local language voice-activated job acceptance and turn-by-turn spoken navigation for Karigars with lower text literacy.")
add_bullet_point("Automated Biometric KYC Verification: ", "Integrating automated government Aadhaar and facial recognition verification APIs to accelerate technician onboarding.")
add_bullet_point("Expanded Commercial & Multi-City Marketplace: ", "Scaling WorkBridge from domestic residential maintenance into commercial property facility management across major metropolitan hubs.")

doc.add_page_break()

# -------------------------------------------------------------
# CHAPTER 9: CONCLUSION AND DISCUSSION
# -------------------------------------------------------------
add_chapter_title("9  CONCLUSION AND DISCUSSION")
add_justified_para(
    "The WorkBridge system successfully provides an advanced, dependable, and equitable digital solution for the on-demand home services industry. "
    "By replacing antiquated, disorganized word-of-mouth practices with a transparent mobile marketplace, the platform eliminates search friction, "
    "standardizes service pricing, introduces rigorous accountability, and significantly improves safety for household consumers."
)
add_justified_para(
    "The adoption of modern engineering technologies—specifically Flutter, Dart, and Google Firebase—enabled the platform to deliver high runtime "
    "performance, fluid cross-platform responsiveness, and resilient real-time cloud data synchronization. The system supports multi-role access control, "
    "dynamic trade category discovery, dual booking dispatching (Broadcast vs Specific Karigar), live OpenStreetMap route tracking, cashless payment processing, "
    "WorkBridge Flex loyalty memberships, and the WorkBridge Safe emergency SOS safety protocol."
)
add_justified_para(
    "From a discussion perspective, WorkBridge directly resolves the longstanding socio-economic challenges that characterize the informal blue-collar economy. "
    "By granting independent artisans (Karigars) a dignified digital presence, verified skill credentials, and transparent direct earnings, the platform fosters "
    "inclusive economic empowerment while freeing technicians from exploitative intermediaries. For homeowners, the combination of upfront price estimates, "
    "live technician GPS tracking, and dedicated in-service safety mechanisms establishes an unprecedented standard of consumer confidence."
)
add_justified_para(
    "In conclusion, WorkBridge is a practical, highly scalable, and user-centric software solution that fulfills all functional, architectural, and academic "
    "requirements. With proposed future additions such as AI safety anomaly detection and multi-lingual voice navigation, WorkBridge possesses immense commercial "
    "potential to become a leading enterprise ecosystem for the modern gig economy."
)

doc.add_page_break()

# -------------------------------------------------------------
# CHAPTER 10: REFERENCES
# -------------------------------------------------------------
add_chapter_title("10  REFERENCES")

refs = [
    ("1. Flutter – Official Documentation", "https://flutter.dev/docs",
     "Flutter documentation was utilized to implement cross-platform reactive mobile UI widgets, state lifecycle management, custom painters, and native build configurations."),
    ("2. Google Firebase – Cloud Firestore & Auth Documentation", "https://firebase.google.com/docs",
     "Firebase documentation was referenced for NoSQL document modeling, real-time snapshot streams, token authentication, and cloud security rules."),
    ("3. OpenStreetMap & Flutter Map Documentation", "https://docs.fleaflet.dev/",
     "Referred for interactive map tile rendering, marker coordinate placement, polyline route drawing, and geolocation integration."),
    ("4. Razorpay – Payment Gateway Developer Documentation", "https://razorpay.com/docs/",
     "Razorpay documentation was used for integrating secure UPI, card, and net banking payment flows, webhooks, and digital transaction verification."),
    ("5. GitHub – Codebase & Architecture Reference", "https://github.com/",
     "GitHub open-source repositories were referenced for studying Clean Architecture design patterns, Provider state notifiers, and repository abstractions in Flutter.")
]

for title, url, desc in refs:
    p_r = doc.add_paragraph()
    r_t = p_r.add_run(title + "\n")
    r_t.font.name = 'Times New Roman'
    r_t.font.size = Pt(11.5)
    r_t.font.bold = True

    r_u = p_r.add_run(url + "\n")
    r_u.font.name = 'Times New Roman'
    r_u.font.size = Pt(10.5)
    r_u.font.color.rgb = RGBColor(2, 132, 199)

    r_d = p_r.add_run(desc)
    r_d.font.name = 'Times New Roman'
    r_d.font.size = Pt(11)

# Save Document
doc.save(DOCX_OUT)
print(f"Generated WorkBridge DOCX: {DOCX_OUT} ({os.path.getsize(DOCX_OUT)} bytes)")
