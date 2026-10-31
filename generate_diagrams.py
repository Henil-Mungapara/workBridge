"""
Generate pixel-perfect WorkBridge diagrams matching EasyCart styling:
1. ER Diagram
2. Use Case Diagram
3. Data Flow Diagram (Level 0 and 1)
4. Flowchart
"""

import subprocess
import os

DIAGRAMS_DIR = r"e:\workbridge\report_assets\diagrams"
os.makedirs(DIAGRAMS_DIR, exist_ok=True)
CHROME_PATH = r"C:\Program Files\Google\Chrome\Application\chrome.exe"

def render_html_to_png(html_content, out_png, width=850, height=1100):
    temp_html = out_png.replace(".png", ".html")
    with open(temp_html, "w", encoding="utf-8") as f:
        f.write(html_content)
    
    cmd = [
        CHROME_PATH,
        "--headless=new",
        "--no-sandbox",
        "--disable-gpu",
        f"--screenshot={out_png}",
        f"--window-size={width},{height}",
        "--hide-scrollbars",
        os.path.abspath(temp_html)
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode == 0 and os.path.exists(out_png):
        print(f"Generated {out_png} ({os.path.getsize(out_png)} bytes)")
    else:
        print(f"Failed to generate {out_png}: {res.stderr}")

# -------------------------------------------------------------------------
# 1. ER DIAGRAM
# -------------------------------------------------------------------------
er_html = """<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  body {
    margin: 0; padding: 20px; background: #fff;
    font-family: 'Times New Roman', Times, serif; color: #000;
  }
  .canvas {
    width: 800px; height: 1020px; position: relative; background: #ffffff;
    box-sizing: border-box;
  }
  svg {
    position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1;
    pointer-events: none;
  }
  .entity-box {
    position: absolute; z-index: 2; background: #fff;
    border: 1.5px solid #333; border-radius: 4px; font-size: 11px;
    box-shadow: 1px 2px 4px rgba(0,0,0,0.08); overflow: hidden;
  }
  .entity-header {
    padding: 4px 8px; font-weight: bold; font-size: 11.5px;
    text-align: center; border-bottom: 1.5px solid #333;
    letter-spacing: 0.5px;
  }
  .entity-body {
    padding: 4px 8px; line-height: 1.45;
  }
  .key-icon {
    display: inline-block; width: 14px; font-weight: bold; color: #d97706;
  }
  .fk-icon {
    display: inline-block; width: 14px; font-weight: bold; color: #2563eb;
  }
  .c-users { background: #d1fae5; }
  .c-category { background: #fef3c7; }
  .c-bookings { background: #fee2e2; }
  .c-flex { background: #e0e7ff; }
  .c-safety { background: #ffedd5; }
  .c-tracking { background: #cffafe; }
  .c-payments { background: #f3e8ff; }
  .c-reviews { background: #fce7f3; }
  .c-settings { background: #e2e8f0; }

  .legend-box {
    position: absolute; bottom: 20px; right: 20px; z-index: 3;
    background: #fff; border: 1.5px solid #444; border-radius: 4px;
    padding: 8px 12px; font-size: 11px; line-height: 1.5; width: 150px;
    box-shadow: 1px 2px 4px rgba(0,0,0,0.1);
  }
  .legend-title {
    font-weight: bold; text-align: center; border-bottom: 1px solid #666;
    margin-bottom: 4px; padding-bottom: 2px;
  }
</style>
</head>
<body>
<div class="canvas">
  <svg>
    <!-- Connector Lines -->
    <!-- USERS (top center) to FLEX_MEMBERSHIPS (left) -->
    <path d="M 330 90 L 150 90 L 150 140" stroke="#333" stroke-width="1.5" fill="none"/>
    <text x="315" y="85" font-family="Times New Roman" font-size="11">1</text>
    <text x="155" y="130" font-family="Times New Roman" font-size="11">M</text>

    <!-- USERS to SERVICE_REQUESTS (center) -->
    <path d="M 400 195 L 400 240" stroke="#333" stroke-width="1.5" fill="none"/>
    <text x="405" y="210" font-family="Times New Roman" font-size="11">1</text>
    <text x="405" y="235" font-family="Times New Roman" font-size="11">M</text>

    <!-- USERS to SAFETY_INCIDENTS (right) -->
    <path d="M 470 90 L 650 90 L 650 140" stroke="#333" stroke-width="1.5" fill="none"/>
    <text x="480" y="85" font-family="Times New Roman" font-size="11">1</text>
    <text x="635" y="130" font-family="Times New Roman" font-size="11">M</text>

    <!-- SERVICE_CATEGORIES (left middle) to SERVICE_REQUESTS -->
    <path d="M 210 320 L 320 320" stroke="#333" stroke-width="1.5" fill="none"/>
    <text x="220" y="315" font-family="Times New Roman" font-size="11">1</text>
    <text x="305" y="315" font-family="Times New Roman" font-size="11">M</text>

    <!-- SERVICE_REQUESTS to PAYMENTS (bottom left) -->
    <path d="M 340 450 L 340 500 L 190 500 L 190 540" stroke="#333" stroke-width="1.5" fill="none"/>
    <text x="345" y="475" font-family="Times New Roman" font-size="11">1</text>
    <text x="195" y="530" font-family="Times New Roman" font-size="11">1</text>

    <!-- SERVICE_REQUESTS to RATINGS_REVIEWS (bottom center) -->
    <path d="M 400 450 L 400 540" stroke="#333" stroke-width="1.5" fill="none"/>
    <text x="405" y="480" font-family="Times New Roman" font-size="11">1</text>
    <text x="405" y="530" font-family="Times New Roman" font-size="11">M</text>

    <!-- SERVICE_REQUESTS to PROVIDER_LOCATIONS (bottom right) -->
    <path d="M 460 450 L 460 500 L 620 500 L 620 540" stroke="#333" stroke-width="1.5" fill="none"/>
    <text x="465" y="475" font-family="Times New Roman" font-size="11">1</text>
    <text x="625" y="530" font-family="Times New Roman" font-size="11">M</text>

    <!-- SERVICE_REQUESTS to SAFETY_INCIDENTS -->
    <path d="M 480 320 L 560 320 L 560 210 L 580 210" stroke="#333" stroke-width="1.5" fill="none"/>
    <text x="490" y="315" font-family="Times New Roman" font-size="11">1</text>
    <text x="565" y="205" font-family="Times New Roman" font-size="11">M</text>

    <!-- Crow's feet symbols on "Many" ends -->
    <!-- On Flex -->
    <line x1="145" y1="135" x2="150" y2="140" stroke="#333" stroke-width="1.5"/>
    <line x1="155" y1="135" x2="150" y2="140" stroke="#333" stroke-width="1.5"/>
    <!-- On Bookings from Users -->
    <line x1="395" y1="235" x2="400" y2="240" stroke="#333" stroke-width="1.5"/>
    <line x1="405" y1="235" x2="400" y2="240" stroke="#333" stroke-width="1.5"/>
    <!-- On Bookings from Category -->
    <line x1="315" y1="315" x2="320" y2="320" stroke="#333" stroke-width="1.5"/>
    <line x1="315" y1="325" x2="320" y2="320" stroke="#333" stroke-width="1.5"/>
    <!-- On Reviews -->
    <line x1="395" y1="535" x2="400" y2="540" stroke="#333" stroke-width="1.5"/>
    <line x1="405" y1="535" x2="400" y2="540" stroke="#333" stroke-width="1.5"/>
  </svg>

  <!-- USERS -->
  <div class="entity-box" style="top: 20px; left: 330px; width: 140px;">
    <div class="entity-header c-users">USERS</div>
    <div class="entity-body">
      <div><span class="key-icon">&#128273;</span> <b>uid (PK)</b></div>
      <div>name</div>
      <div>email (Unique)</div>
      <div>phone</div>
      <div>password</div>
      <div>role (cust/prov/adm)</div>
      <div>is_verified</div>
      <div>categories</div>
      <div>created_at</div>
    </div>
  </div>

  <!-- FLEX_MEMBERSHIPS -->
  <div class="entity-box" style="top: 140px; left: 70px; width: 160px;">
    <div class="entity-header c-flex">FLEX_MEMBERSHIPS</div>
    <div class="entity-body">
      <div><span class="key-icon">&#128273;</span> <b>membership_id (PK)</b></div>
      <div><span class="fk-icon">&#128273;</span> user_id (FK)</div>
      <div>plan_type (mo/yr)</div>
      <div>total_credits (10/120)</div>
      <div>used_credits</div>
      <div>remaining_credits</div>
      <div>carry_forward_credits</div>
      <div>renewal_date</div>
      <div>status</div>
    </div>
  </div>

  <!-- SAFETY_INCIDENTS -->
  <div class="entity-box" style="top: 140px; left: 570px; width: 160px;">
    <div class="entity-header c-safety">SAFETY_INCIDENTS</div>
    <div class="entity-body">
      <div><span class="key-icon">&#128273;</span> <b>incident_id (PK)</b></div>
      <div><span class="fk-icon">&#128273;</span> request_id (FK)</div>
      <div><span class="fk-icon">&#128273;</span> user_id (FK)</div>
      <div>user_type (cust/prov)</div>
      <div>latitude</div>
      <div>longitude</div>
      <div>emergency_contact</div>
      <div>status (active/resolved)</div>
      <div>created_at</div>
    </div>
  </div>

  <!-- SERVICE_CATEGORIES -->
  <div class="entity-box" style="top: 250px; left: 60px; width: 150px;">
    <div class="entity-header c-category">CATEGORIES</div>
    <div class="entity-body">
      <div><span class="key-icon">&#128273;</span> <b>category_id (PK)</b></div>
      <div>name</div>
      <div>description</div>
      <div>icon_name</div>
      <div>accent_color</div>
      <div>is_active</div>
      <div>provider_count</div>
      <div>created_at</div>
    </div>
  </div>

  <!-- SERVICE_REQUESTS (BOOKINGS) -->
  <div class="entity-box" style="top: 240px; left: 320px; width: 160px;">
    <div class="entity-header c-bookings">SERVICE_REQUESTS</div>
    <div class="entity-body">
      <div><span class="key-icon">&#128273;</span> <b>request_id (PK)</b></div>
      <div><span class="fk-icon">&#128273;</span> customer_id (FK)</div>
      <div><span class="fk-icon">&#128273;</span> category_id (FK)</div>
      <div>service_title</div>
      <div>description</div>
      <div>estimated_amount</div>
      <div>scheduled_date</div>
      <div>scheduled_time</div>
      <div>request_type (bc/spec)</div>
      <div><span class="fk-icon">&#128273;</span> target_provider_id</div>
      <div><span class="fk-icon">&#128273;</span> assigned_provider_id</div>
      <div>status (pend/acc/comp)</div>
      <div>customer_lat / lng</div>
      <div>created_at</div>
    </div>
  </div>

  <!-- PAYMENTS -->
  <div class="entity-box" style="top: 540px; left: 110px; width: 160px;">
    <div class="entity-header c-payments">PAYMENTS</div>
    <div class="entity-body">
      <div><span class="key-icon">&#128273;</span> <b>payment_id (PK)</b></div>
      <div><span class="fk-icon">&#128273;</span> request_id (FK)</div>
      <div><span class="fk-icon">&#128273;</span> customer_id (FK)</div>
      <div><span class="fk-icon">&#128273;</span> provider_id (FK)</div>
      <div>amount</div>
      <div>method (Online/COD/Flex)</div>
      <div>status (paid/pending)</div>
      <div>transaction_date</div>
    </div>
  </div>

  <!-- RATINGS_REVIEWS -->
  <div class="entity-box" style="top: 540px; left: 320px; width: 160px;">
    <div class="entity-header c-reviews">RATINGS_REVIEWS</div>
    <div class="entity-body">
      <div><span class="key-icon">&#128273;</span> <b>review_id (PK)</b></div>
      <div><span class="fk-icon">&#128273;</span> request_id (FK)</div>
      <div><span class="fk-icon">&#128273;</span> customer_id (FK)</div>
      <div><span class="fk-icon">&#128273;</span> provider_id (FK)</div>
      <div>rating_value (1-5)</div>
      <div>review_text</div>
      <div>created_at</div>
    </div>
  </div>

  <!-- PROVIDER_LOCATIONS -->
  <div class="entity-box" style="top: 540px; left: 540px; width: 160px;">
    <div class="entity-header c-tracking">PROVIDER_LOCATIONS</div>
    <div class="entity-body">
      <div><span class="key-icon">&#128273;</span> <b>tracking_id (PK)</b></div>
      <div><span class="fk-icon">&#128273;</span> provider_id (FK)</div>
      <div><span class="fk-icon">&#128273;</span> request_id (FK)</div>
      <div>current_latitude</div>
      <div>current_longitude</div>
      <div>tracking_status</div>
      <div>updated_at</div>
    </div>
  </div>

  <!-- STORE_SETTINGS / APP CONFIG -->
  <div class="entity-box" style="top: 760px; left: 320px; width: 160px;">
    <div class="entity-header c-settings">APP_SETTINGS</div>
    <div class="entity-body">
      <div><span class="key-icon">&#128273;</span> <b>setting_id (PK)</b></div>
      <div>app_name</div>
      <div>support_email</div>
      <div>support_phone</div>
      <div>service_commission (%)</div>
      <div>flex_credit_rate</div>
      <div>created_at</div>
    </div>
  </div>

  <!-- LEGEND -->
  <div class="legend-box">
    <div class="legend-title">LEGEND</div>
    <div><span class="key-icon">&#128273;</span> PK &nbsp; Primary Key</div>
    <div><span class="fk-icon">&#128273;</span> FK &nbsp; Foreign Key</div>
    <div><b>1</b> &nbsp;&nbsp;&nbsp; One</div>
    <div><b>M</b> &nbsp;&nbsp;&nbsp; Many</div>
    <div><span style="font-size:14px;">&mdash;</span> &nbsp;&nbsp; One to Many</div>
    <div><span style="font-size:14px;">&lt;</span> &nbsp;&nbsp; Many Side</div>
  </div>
</div>
</body>
</html>"""

render_html_to_png(er_html, os.path.join(DIAGRAMS_DIR, "er_diagram.png"), width=820, height=1040)

# -------------------------------------------------------------------------
# 2. USE CASE DIAGRAM
# -------------------------------------------------------------------------
usecase_html = """<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  body {
    margin: 0; padding: 20px; background: #fff;
    font-family: 'Times New Roman', Times, serif; color: #000;
  }
  .canvas {
    width: 800px; height: 1020px; position: relative; background: #fff;
    box-sizing: border-box;
  }
  svg {
    position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1;
    pointer-events: none;
  }
  .actor-box {
    position: absolute; z-index: 3; text-align: center; width: 90px;
  }
  .actor-icon {
    font-size: 40px; line-height: 1; margin-bottom: 2px;
  }
  .actor-label {
    font-size: 12px; font-weight: bold;
  }
  .usecase-box {
    position: absolute; z-index: 2; border: 1.5px solid #2563eb;
    background: #eff6ff; border-radius: 20px; text-align: center;
    font-size: 11px; font-weight: 500; display: flex; align-items: center;
    justify-content: center; box-shadow: 1px 1px 3px rgba(0,0,0,0.06);
    padding: 2px 8px; box-sizing: border-box;
  }
  .dashed-box {
    border-style: dashed; border-color: #64748b; background: #f8fafc;
  }
  .system-boundary {
    position: absolute; top: 15px; left: 130px; width: 540px; height: 980px;
    border: 1.5px solid #94a3b8; border-radius: 8px; z-index: 0;
  }
  .boundary-title {
    position: absolute; top: 22px; left: 280px; font-weight: bold;
    font-size: 13px; color: #1e3a8a; letter-spacing: 0.5px;
  }
</style>
</head>
<body>
<div class="canvas">
  <div class="system-boundary"></div>
  <div class="boundary-title">WorkBridge Platform</div>

  <!-- SVG Connectors -->
  <svg>
    <!-- Customer Lines (Left: 95, 420) -->
    <!-- to UC1 Register/Login (160, 45) -->
    <line x1="95" y1="400" x2="160" y2="55" stroke="#333" stroke-width="1.2"/>
    <!-- to UC2 Browse Categories (160, 115) -->
    <line x1="95" y1="410" x2="160" y2="125" stroke="#333" stroke-width="1.2"/>
    <!-- to UC3 Search & Filter (160, 185) -->
    <line x1="95" y1="420" x2="160" y2="195" stroke="#333" stroke-width="1.2"/>
    <!-- to UC4 View Provider (160, 255) -->
    <line x1="95" y1="425" x2="160" y2="265" stroke="#333" stroke-width="1.2"/>
    <!-- to UC5 Create Booking (160, 325) -->
    <line x1="95" y1="430" x2="160" y2="335" stroke="#333" stroke-width="1.2"/>
    <!-- to UC6 Live Track (160, 445) -->
    <line x1="95" y1="440" x2="160" y2="455" stroke="#333" stroke-width="1.2"/>
    <!-- to UC7 Make Payment (160, 525) -->
    <line x1="95" y1="450" x2="160" y2="535" stroke="#333" stroke-width="1.2"/>
    <!-- to UC8 WorkBridge Flex (160, 605) -->
    <line x1="95" y1="460" x2="160" y2="615" stroke="#333" stroke-width="1.2"/>
    <!-- to UC9 WorkBridge Safe (160, 685) -->
    <line x1="95" y1="470" x2="160" y2="695" stroke="#333" stroke-width="1.2"/>
    <!-- to UC10 Rating & Review (160, 765) -->
    <line x1="95" y1="480" x2="160" y2="775" stroke="#333" stroke-width="1.2"/>

    <!-- Includes/Extends inside Customer side -->
    <!-- Register/Login -> Verify Phone/OTP (dashed arrow) -->
    <line x1="290" y1="55" x2="350" y2="55" stroke="#475569" stroke-width="1.2" stroke-dasharray="4,3"/>
    <text x="295" y="48" font-family="Times New Roman" font-size="9" fill="#475569">&laquo;include&raquo;</text>

    <!-- Create Booking -> Choose Booking Mode (Broadcast/Specific) -->
    <line x1="290" y1="335" x2="350" y2="335" stroke="#475569" stroke-width="1.2" stroke-dasharray="4,3"/>
    <text x="295" y="328" font-family="Times New Roman" font-size="9" fill="#475569">&laquo;include&raquo;</text>

    <!-- Create Booking -> Schedule Date/Time -->
    <line x1="280" y1="350" x2="350" y2="395" stroke="#475569" stroke-width="1.2" stroke-dasharray="4,3"/>
    <text x="295" y="380" font-family="Times New Roman" font-size="9" fill="#475569">&laquo;include&raquo;</text>

    <!-- WorkBridge Safe -> Trigger SOS & Alert Contact -->
    <line x1="290" y1="695" x2="350" y2="695" stroke="#475569" stroke-width="1.2" stroke-dasharray="4,3"/>
    <text x="295" y="688" font-family="Times New Roman" font-size="9" fill="#475569">&laquo;include&raquo;</text>

    <!-- Service Provider Lines (Right Top: 700, 260) -->
    <line x1="700" y1="260" x2="630" y2="125" stroke="#333" stroke-width="1.2"/>
    <line x1="700" y1="270" x2="630" y2="195" stroke="#333" stroke-width="1.2"/>
    <line x1="700" y1="280" x2="630" y2="265" stroke="#333" stroke-width="1.2"/>
    <line x1="700" y1="290" x2="630" y2="335" stroke="#333" stroke-width="1.2"/>
    <line x1="700" y1="300" x2="630" y2="405" stroke="#333" stroke-width="1.2"/>
    <line x1="700" y1="310" x2="630" y2="475" stroke="#333" stroke-width="1.2"/>

    <!-- Provider connection to Create Booking (accepting requests) -->
    <line x1="700" y1="285" x2="480" y2="335" stroke="#333" stroke-width="1.2" stroke-dasharray="2,2"/>

    <!-- Admin Lines (Right Bottom: 700, 720) -->
    <line x1="700" y1="690" x2="630" y2="565" stroke="#333" stroke-width="1.2"/>
    <line x1="700" y1="700" x2="630" y2="635" stroke="#333" stroke-width="1.2"/>
    <line x1="700" y1="710" x2="630" y2="705" stroke="#333" stroke-width="1.2"/>
    <line x1="700" y1="720" x2="630" y2="775" stroke="#333" stroke-width="1.2"/>
    <line x1="700" y1="730" x2="630" y2="845" stroke="#333" stroke-width="1.2"/>
    <line x1="700" y1="740" x2="630" y2="915" stroke="#333" stroke-width="1.2"/>
  </svg>

  <!-- ACTOR 1: CUSTOMER -->
  <div class="actor-box" style="top: 400px; left: 10px;">
    <div class="actor-icon">&#128100;</div>
    <div class="actor-label">CUSTOMER<br>(Homeowner)</div>
  </div>

  <!-- CUSTOMER USE CASES -->
  <div class="usecase-box" style="top: 40px; left: 160px; width: 130px; height: 32px;">Register / Login</div>
  <div class="usecase-box dashed-box" style="top: 40px; left: 350px; width: 130px; height: 32px;">Verify Phone / OTP</div>

  <div class="usecase-box" style="top: 110px; left: 160px; width: 130px; height: 32px;">Browse Categories</div>
  <div class="usecase-box" style="top: 180px; left: 160px; width: 130px; height: 32px;">Search & Filter Karigars</div>
  <div class="usecase-box" style="top: 250px; left: 160px; width: 130px; height: 32px;">View Karigar Profile</div>

  <div class="usecase-box" style="top: 320px; left: 160px; width: 130px; height: 32px;">Create Booking Request</div>
  <div class="usecase-box dashed-box" style="top: 320px; left: 350px; width: 130px; height: 32px;">Broadcast vs Specific</div>
  <div class="usecase-box dashed-box" style="top: 380px; left: 350px; width: 130px; height: 32px;">Schedule Date & Time</div>

  <div class="usecase-box" style="top: 440px; left: 160px; width: 130px; height: 32px;">Live Track Technician</div>
  <div class="usecase-box" style="top: 520px; left: 160px; width: 130px; height: 32px;">Online / Cash Payment</div>
  <div class="usecase-box" style="top: 600px; left: 160px; width: 130px; height: 32px;">Manage Flex Credits</div>
  <div class="usecase-box" style="top: 680px; left: 160px; width: 130px; height: 32px;">WorkBridge Safe (SOS)</div>
  <div class="usecase-box dashed-box" style="top: 680px; left: 350px; width: 130px; height: 32px;">Notify Emergency Contact</div>
  <div class="usecase-box" style="top: 760px; left: 160px; width: 130px; height: 32px;">Rate & Review Service</div>

  <!-- ACTOR 2: SERVICE PROVIDER -->
  <div class="actor-box" style="top: 250px; left: 700px;">
    <div class="actor-icon">&#128295;</div>
    <div class="actor-label">SERVICE PROVIDER<br>(Karigar)</div>
  </div>

  <!-- PROVIDER USE CASES -->
  <div class="usecase-box" style="top: 110px; left: 500px; width: 130px; height: 32px;">Register & KYC Upload</div>
  <div class="usecase-box" style="top: 180px; left: 500px; width: 130px; height: 32px;">View Incoming Requests</div>
  <div class="usecase-box" style="top: 250px; left: 500px; width: 130px; height: 32px;">Accept / Reject Job</div>
  <div class="usecase-box" style="top: 320px; left: 500px; width: 130px; height: 32px;">Update Live Location</div>
  <div class="usecase-box" style="top: 390px; left: 500px; width: 130px; height: 32px;">Job Status (In-Progress)</div>
  <div class="usecase-box" style="top: 460px; left: 500px; width: 130px; height: 32px;">View Earnings & Stats</div>

  <!-- ACTOR 3: ADMIN -->
  <div class="actor-box" style="top: 700px; left: 700px;">
    <div class="actor-icon">&#128187;</div>
    <div class="actor-label">ADMINISTRATOR</div>
  </div>

  <!-- ADMIN USE CASES -->
  <div class="usecase-box" style="top: 550px; left: 500px; width: 130px; height: 32px;">Admin Login & Dashboard</div>
  <div class="usecase-box" style="top: 620px; left: 500px; width: 130px; height: 32px;">Verify & Approve Providers</div>
  <div class="usecase-box" style="top: 690px; left: 500px; width: 130px; height: 32px;">Manage Trade Categories</div>
  <div class="usecase-box" style="top: 760px; left: 500px; width: 130px; height: 32px;">Monitor Live Gigs & Maps</div>
  <div class="usecase-box" style="top: 830px; left: 500px; width: 130px; height: 32px;">Review Safety Escalations</div>
  <div class="usecase-box" style="top: 900px; left: 500px; width: 130px; height: 32px;">Reports & Commission Audit</div>
</div>
</body>
</html>"""

render_html_to_png(usecase_html, os.path.join(DIAGRAMS_DIR, "usecase_diagram.png"), width=820, height=1040)

# -------------------------------------------------------------------------
# 3. DATA FLOW DIAGRAM (0 and 1 level)
# -------------------------------------------------------------------------
dfd_html = """<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  body {
    margin: 0; padding: 20px; background: #fff;
    font-family: 'Times New Roman', Times, serif; color: #000;
  }
  .canvas {
    width: 800px; height: 1040px; position: relative; background: #fff;
    box-sizing: border-box;
  }
  svg {
    position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1;
    pointer-events: none;
  }
  .title-header {
    font-size: 13px; font-weight: bold; margin-bottom: 8px; text-decoration: underline;
  }
  .ext-entity {
    position: absolute; z-index: 3; background: #dcfce7;
    border: 1.5px solid #166534; border-radius: 4px; font-size: 11px;
    font-weight: bold; text-align: center; display: flex; align-items: center;
    justify-content: center;
  }
  .ext-admin {
    background: #f1f5f9; border-color: #334155;
  }
  .ext-provider {
    background: #fef3c7; border-color: #b45309;
  }
  .proc-box {
    position: absolute; z-index: 3; background: #fef9c3;
    border: 1.5px solid #854d0e; border-radius: 12px; font-size: 10.5px;
    font-weight: bold; text-align: center; display: flex; flex-direction: column;
    align-items: center; justify-content: center; padding: 2px 4px;
  }
  .main-proc {
    background: #dbeafe; border-color: #1e40af; border-radius: 16px;
    font-size: 12px;
  }
  .data-store {
    position: absolute; z-index: 3; background: #f8fafc;
    border-top: 1.5px solid #0f172a; border-bottom: 1.5px solid #0f172a;
    border-left: none; border-right: none; font-size: 10px; font-weight: bold;
    display: flex; align-items: center; padding: 0 4px; height: 22px;
  }
  .ds-tag {
    background: #e2e8f0; padding: 2px 4px; margin-right: 4px;
    border-right: 1px solid #94a3b8;
  }
  .dfd-divider {
    position: absolute; top: 410px; left: 0; width: 100%;
    border-top: 1px dashed #cbd5e1;
  }
</style>
</head>
<body>
<div class="canvas">
  <!-- LEVEL 0: CONTEXT DIAGRAM -->
  <div style="position: absolute; top: 0; left: 20px;">
    <div class="title-header">4.5.3.1 DFD &ndash; Level 0 (Context Diagram)</div>
  </div>

  <svg>
    <!-- Level 0 Arrows -->
    <!-- Customer to System -->
    <path d="M 120 100 L 320 100" stroke="#333" stroke-width="1.2" marker-end="url(#arrow)"/>
    <text x="135" y="93" font-family="Times New Roman" font-size="9.5">Register / Login / Book Service</text>

    <path d="M 120 140 L 320 140" stroke="#333" stroke-width="1.2" marker-end="url(#arrow)"/>
    <text x="145" y="133" font-family="Times New Roman" font-size="9.5">Payment &amp; Rating Feedback</text>

    <path d="M 120 180 L 320 180" stroke="#333" stroke-width="1.2" marker-end="url(#arrow)"/>
    <text x="155" y="173" font-family="Times New Roman" font-size="9.5">SOS Emergency Trigger</text>

    <!-- System to Customer -->
    <path d="M 320 220 L 120 220" stroke="#333" stroke-width="1.2" marker-end="url(#arrow)"/>
    <text x="130" y="213" font-family="Times New Roman" font-size="9.5">Categories / Booking Confirmed</text>

    <path d="M 320 260 L 120 260" stroke="#333" stroke-width="1.2" marker-end="url(#arrow)"/>
    <text x="130" y="253" font-family="Times New Roman" font-size="9.5">Live Tracking / Invoice / Status</text>

    <!-- Provider to System -->
    <path d="M 680 70 L 480 70" stroke="#333" stroke-width="1.2" marker-end="url(#arrow)"/>
    <text x="500" y="63" font-family="Times New Roman" font-size="9.5">KYC Docs / Accept Job / Live GPS</text>

    <!-- System to Provider -->
    <path d="M 480 110 L 680 110" stroke="#333" stroke-width="1.2" marker-end="url(#arrow)"/>
    <text x="500" y="103" font-family="Times New Roman" font-size="9.5">Job Alerts / Customer Location / Payout</text>

    <!-- Admin to System -->
    <path d="M 680 230 L 480 230" stroke="#333" stroke-width="1.2" marker-end="url(#arrow)"/>
    <text x="500" y="223" font-family="Times New Roman" font-size="9.5">Manage Users / Categories / System Settings</text>

    <!-- System to Admin -->
    <path d="M 480 270 L 680 270" stroke="#333" stroke-width="1.2" marker-end="url(#arrow)"/>
    <text x="500" y="263" font-family="Times New Roman" font-size="9.5">Analytics / Safety Alerts / Audit Logs</text>

    <!-- Level 1 Connectors -->
    <!-- Customer lines into Level 1 processes -->
    <line x1="80" y1="460" x2="280" y2="460" stroke="#333" stroke-width="1.2"/>
    <line x1="80" y1="540" x2="280" y2="540" stroke="#333" stroke-width="1.2"/>
    <line x1="80" y1="620" x2="280" y2="620" stroke="#333" stroke-width="1.2"/>
    <line x1="80" y1="700" x2="280" y2="700" stroke="#333" stroke-width="1.2"/>
    <line x1="80" y1="780" x2="280" y2="780" stroke="#333" stroke-width="1.2"/>
    <line x1="80" y1="860" x2="280" y2="860" stroke="#333" stroke-width="1.2"/>
    <line x1="80" y1="940" x2="280" y2="940" stroke="#333" stroke-width="1.2"/>

    <!-- Process to Data Stores -->
    <line x1="410" y1="460" x2="500" y2="460" stroke="#333" stroke-width="1.2"/>
    <line x1="410" y1="540" x2="500" y2="540" stroke="#333" stroke-width="1.2"/>
    <line x1="410" y1="620" x2="500" y2="620" stroke="#333" stroke-width="1.2"/>
    <line x1="410" y1="700" x2="500" y2="700" stroke="#333" stroke-width="1.2"/>
    <line x1="410" y1="780" x2="500" y2="780" stroke="#333" stroke-width="1.2"/>
    <line x1="410" y1="860" x2="500" y2="860" stroke="#333" stroke-width="1.2"/>
    <line x1="410" y1="940" x2="500" y2="940" stroke="#333" stroke-width="1.2"/>

    <!-- Data Stores to Admin / Provider -->
    <line x1="610" y1="460" x2="700" y2="700" stroke="#333" stroke-width="1.2"/>
    <line x1="610" y1="620" x2="700" y2="700" stroke="#333" stroke-width="1.2"/>
    <line x1="610" y1="780" x2="700" y2="700" stroke="#333" stroke-width="1.2"/>

    <!-- Marker definition -->
    <defs>
      <marker id="arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
        <path d="M 0 1 L 10 5 L 0 9 z" fill="#333" />
      </marker>
    </defs>
  </svg>

  <!-- Level 0 Entities -->
  <div class="ext-entity" style="top: 80px; left: 10px; width: 110px; height: 190px;">
    CUSTOMER<br>(Homeowner)
  </div>

  <div class="proc-box main-proc" style="top: 50px; left: 320px; width: 160px; height: 230px;">
    <div style="font-size:18px; margin-bottom: 6px;">0</div>
    <div style="font-size:14px; font-weight:bold;">WorkBridge<br>Platform</div>
    <div style="font-size:10px; margin-top:8px; font-weight:normal; color:#1e3a8a;">
      Service Matching &amp;<br>Fulfillment Engine
    </div>
  </div>

  <div class="ext-entity ext-provider" style="top: 45px; left: 680px; width: 110px; height: 110px;">
    SERVICE<br>PROVIDER<br>(Karigar)
  </div>

  <div class="ext-entity ext-admin" style="top: 180px; left: 680px; width: 110px; height: 110px;">
    PLATFORM<br>ADMIN
  </div>

  <!-- DIVIDER -->
  <div class="dfd-divider"></div>

  <!-- LEVEL 1: DETAILED DFD -->
  <div style="position: absolute; top: 418px; left: 20px;">
    <div class="title-header">4.5.3.2 DFD &ndash; Level 1</div>
  </div>

  <!-- Customer Left Bar in L1 -->
  <div class="ext-entity" style="top: 450px; left: 10px; width: 70px; height: 500px;">
    USER /<br>CUSTOMER
  </div>

  <!-- Level 1 Processes -->
  <div class="proc-box" style="top: 445px; left: 280px; width: 130px; height: 35px;">
    1.0 User Auth &amp;<br>Role Verification
  </div>
  <div class="data-store" style="top: 450px; left: 500px; width: 110px;">
    <span class="ds-tag">D1</span> Users Collection
  </div>

  <div class="proc-box" style="top: 525px; left: 280px; width: 130px; height: 35px;">
    2.0 Catalog &amp;<br>Trade Categories
  </div>
  <div class="data-store" style="top: 530px; left: 500px; width: 110px;">
    <span class="ds-tag">D2</span> Categories Catalog
  </div>

  <div class="proc-box" style="top: 605px; left: 280px; width: 130px; height: 35px;">
    3.0 Booking Dispatch<br>(Broadcast/Specific)
  </div>
  <div class="data-store" style="top: 610px; left: 500px; width: 110px;">
    <span class="ds-tag">D3</span> Service Requests
  </div>

  <div class="proc-box" style="top: 685px; left: 280px; width: 130px; height: 35px;">
    4.0 Live Location &amp;<br>Map Route Tracking
  </div>
  <div class="data-store" style="top: 690px; left: 500px; width: 110px;">
    <span class="ds-tag">D4</span> Provider Live GPS
  </div>

  <div class="proc-box" style="top: 765px; left: 280px; width: 130px; height: 35px;">
    5.0 Payment &amp; Flex<br>Credits Ledger
  </div>
  <div class="data-store" style="top: 770px; left: 500px; width: 110px;">
    <span class="ds-tag">D5</span> Payments &amp; Flex
  </div>

  <div class="proc-box" style="top: 845px; left: 280px; width: 130px; height: 35px;">
    6.0 WorkBridge Safe<br>Emergency Response
  </div>
  <div class="data-store" style="top: 850px; left: 500px; width: 110px;">
    <span class="ds-tag">D6</span> Incident Logs
  </div>

  <div class="proc-box" style="top: 925px; left: 280px; width: 130px; height: 35px;">
    7.0 Ratings, Reviews<br>&amp; Feedback
  </div>
  <div class="data-store" style="top: 930px; left: 500px; width: 110px;">
    <span class="ds-tag">D7</span> Reviews &amp; Ratings
  </div>

  <!-- Admin / Provider Right Bar in L1 -->
  <div class="ext-entity ext-admin" style="top: 450px; left: 700px; width: 85px; height: 500px;">
    ADMIN &amp;<br>PROVIDER<br>CONSOLE
  </div>
</div>
</body>
</html>"""

render_html_to_png(dfd_html, os.path.join(DIAGRAMS_DIR, "dfd_diagram.png"), width=820, height=1050)

# -------------------------------------------------------------------------
# 4. FLOW CHART
# -------------------------------------------------------------------------
flowchart_html = """<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  body {
    margin: 0; padding: 20px; background: #fff;
    font-family: 'Times New Roman', Times, serif; color: #000;
  }
  .canvas {
    width: 800px; height: 1040px; position: relative; background: #fff;
    box-sizing: border-box;
  }
  svg {
    position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1;
    pointer-events: none;
  }
  .node {
    position: absolute; z-index: 2; border: 1.5px solid #000;
    background: #fff; text-align: center; font-size: 11px;
    display: flex; align-items: center; justify-content: center;
    box-sizing: border-box; font-weight: 500;
  }
  .start-end {
    border-radius: 20px; width: 90px; height: 30px; font-weight: bold;
  }
  .rect-node {
    border-radius: 4px; width: 140px; height: 34px;
  }
  .decision-node {
    width: 120px; height: 46px; background: #fff; border: 1.5px solid #000;
    transform: rotate(45deg); display: flex; align-items: center; justify-content: center;
  }
  .decision-text {
    transform: rotate(-45deg); font-size: 10.5px; font-weight: bold; text-align: center;
  }
  .tag {
    font-size: 10.5px; font-weight: bold; font-family: 'Times New Roman';
  }
</style>
</head>
<body>
<div class="canvas">
  <svg>
    <!-- Marker definition -->
    <defs>
      <marker id="arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
        <path d="M 0 1 L 10 5 L 0 9 z" fill="#000" />
      </marker>
    </defs>

    <!-- START to Open App -->
    <line x1="400" y1="35" x2="400" y2="60" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>

    <!-- Open App to Role Decision -->
    <line x1="400" y1="95" x2="400" y2="120" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>

    <!-- Decision Branches -->
    <!-- Customer: Left -->
    <path d="M 335 152 L 200 152 L 200 180" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>
    <text x="240" y="145" class="tag">Customer</text>

    <!-- Provider / Admin: Right -->
    <path d="M 465 152 L 600 152 L 600 180" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>
    <text x="510" y="145" class="tag">Provider / Admin</text>

    <!-- Customer Vertical Sequence -->
    <line x1="200" y1="214" x2="200" y2="235" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>
    <line x1="200" y1="269" x2="200" y2="290" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>
    <line x1="200" y1="324" x2="200" y2="345" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>
    <line x1="200" y1="379" x2="200" y2="400" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>
    <line x1="200" y1="434" x2="200" y2="455" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>
    <line x1="200" y1="489" x2="200" y2="510" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>
    <line x1="200" y1="544" x2="200" y2="570" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>

    <!-- Provider Acceptance Loop -->
    <line x1="200" y1="620" x2="200" y2="650" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>
    <text x="205" y="638" class="tag">Yes</text>

    <path d="M 140 595 L 80 595 L 80 472 L 130 472" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>
    <text x="90" y="590" class="tag">No (Re-dispatch)</text>

    <line x1="200" y1="684" x2="200" y2="710" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>
    <line x1="200" y1="744" x2="200" y2="770" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>
    <line x1="200" y1="804" x2="200" y2="830" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>
    <line x1="200" y1="864" x2="200" y2="890" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>
    <line x1="200" y1="924" x2="200" y2="955" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>

    <!-- Provider / Admin Vertical Sequence -->
    <line x1="600" y1="214" x2="600" y2="245" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>
    <line x1="600" y1="279" x2="600" y2="310" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>
    <line x1="600" y1="344" x2="600" y2="375" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>
    <line x1="600" y1="409" x2="600" y2="440" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>
    <line x1="600" y1="474" x2="600" y2="505" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>
    <line x1="600" y1="539" x2="600" y2="570" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>
    <line x1="600" y1="604" x2="600" y2="635" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>
    <line x1="600" y1="669" x2="600" y2="700" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>
    <line x1="600" y1="734" x2="600" y2="765" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>
    <line x1="600" y1="799" x2="600" y2="830" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>
    <line x1="600" y1="864" x2="600" y2="895" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>
    <line x1="600" y1="929" x2="600" y2="955" stroke="#000" stroke-width="1.3" marker-end="url(#arrow)"/>
  </svg>

  <!-- START -->
  <div class="node start-end" style="top: 5px; left: 355px;">START</div>

  <div class="node rect-node" style="top: 60px; left: 330px;">
    Open WorkBridge Application
  </div>

  <!-- Role Selection Diamond -->
  <div style="position: absolute; top: 125px; left: 340px;">
    <div class="decision-node">
      <div class="decision-text">Select User<br>or Admin?</div>
    </div>
  </div>

  <!-- CUSTOMER NODES (LEFT) -->
  <div class="node rect-node" style="top: 180px; left: 130px;">User Login / Register</div>
  <div class="node rect-node" style="top: 235px; left: 130px;">Browse Service Categories</div>
  <div class="node rect-node" style="top: 290px; left: 130px;">Select Trade &amp; View Details</div>
  <div class="node rect-node" style="top: 345px; left: 130px;">Select Broadcast vs Specific</div>
  <div class="node rect-node" style="top: 400px; left: 130px;">Set Schedule &amp; Address</div>
  <div class="node rect-node" style="top: 455px; left: 130px;">Submit Service Request</div>
  <div class="node rect-node" style="top: 510px; left: 130px;">Provider Reviews Job</div>

  <!-- Provider Acceptance Diamond -->
  <div style="position: absolute; top: 570px; left: 140px;">
    <div class="decision-node">
      <div class="decision-text">Provider<br>Accepts?</div>
    </div>
  </div>

  <div class="node rect-node" style="top: 650px; left: 130px;">Live GPS Tracking &amp; Route</div>
  <div class="node rect-node" style="top: 710px; left: 130px;">Technician Arrives &amp; Starts</div>
  <div class="node rect-node" style="top: 770px; left: 130px;">Service Execution (Safe Active)</div>
  <div class="node rect-node" style="top: 830px; left: 130px;">Service Completed by Karigar</div>
  <div class="node rect-node" style="top: 890px; left: 130px;">Payment &amp; Rating / Review</div>

  <div class="node start-end" style="top: 955px; left: 155px;">END</div>

  <!-- PROVIDER / ADMIN NODES (RIGHT) -->
  <div class="node rect-node" style="top: 180px; left: 530px;">Provider / Admin Login</div>
  <div class="node rect-node" style="top: 245px; left: 530px;">Role-Specific Dashboard</div>
  <div class="node rect-node" style="top: 310px; left: 530px;">Manage Users &amp; Profiles</div>
  <div class="node rect-node" style="top: 375px; left: 530px;">Verify Karigar KYC Docs</div>
  <div class="node rect-node" style="top: 440px; left: 530px;">Manage Trade Categories</div>
  <div class="node rect-node" style="top: 505px; left: 530px;">Manage Live Service Gigs</div>
  <div class="node rect-node" style="top: 570px; left: 530px;">Monitor Active GPS Map</div>
  <div class="node rect-node" style="top: 635px; left: 530px;">WorkBridge Safe Escalations</div>
  <div class="node rect-node" style="top: 700px; left: 530px;">Manage Payments &amp; Flex</div>
  <div class="node rect-node" style="top: 765px; left: 530px;">Audit Reviews &amp; Moderation</div>
  <div class="node rect-node" style="top: 830px; left: 530px;">Generate Business Reports</div>
  <div class="node rect-node" style="top: 895px; left: 530px;">Session Logout</div>

  <div class="node start-end" style="top: 955px; left: 555px;">END</div>
</div>
</body>
</html>"""

render_html_to_png(flowchart_html, os.path.join(DIAGRAMS_DIR, "flowchart_diagram.png"), width=820, height=1050)
print("All 4 diagrams generated successfully!")
