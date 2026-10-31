"""
Generate high-fidelity UI screenshot assets for WorkBridge Report Section 7.
"""

import subprocess
import os

SCREENS_DIR = r"e:\workbridge\report_assets\screens"
os.makedirs(SCREENS_DIR, exist_ok=True)
CHROME_PATH = r"C:\Program Files\Google\Chrome\Application\chrome.exe"

def render_screen(html_content, out_png, width=900, height=520):
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
        print(f"Generated {out_png}")
    else:
        print(f"Failed to generate {out_png}: {res.stderr}")

# Common CSS for Mobile Screen
MOBILE_CSS = """
  * { box-sizing: border-box; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
  body { margin: 0; padding: 10px; background: #e2e8f0; display: flex; justify-content: center; align-items: center; }
  .phone-frame {
    width: 380px; height: 500px; background: #ffffff; border-radius: 28px;
    box-shadow: 0 10px 25px rgba(0,0,0,0.15); border: 8px solid #1e293b;
    position: relative; overflow: hidden; display: flex; flex-direction: column;
  }
  .status-bar {
    height: 24px; background: #008f80; color: #fff; font-size: 11px; font-weight: 600;
    display: flex; justify-content: space-between; align-items: center; padding: 0 16px;
  }
  .app-bar {
    height: 48px; background: #00A896; color: #fff; display: flex; align-items: center;
    justify-content: space-between; padding: 0 14px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  }
  .app-title { font-size: 16px; font-weight: bold; display: flex; align-items: center; gap: 6px; }
  .screen-content { flex: 1; overflow-y: hidden; padding: 12px; background: #f8fafc; }
  .nav-bar {
    height: 44px; background: #fff; border-top: 1px solid #e2e8f0; display: flex;
    justify-content: space-around; align-items: center; font-size: 9px; color: #64748b;
  }
  .nav-item.active { color: #00A896; font-weight: bold; }
"""

# Common CSS for Desktop Admin Screen
ADMIN_CSS = """
  * { box-sizing: border-box; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
  body { margin: 0; padding: 10px; background: #cbd5e1; display: flex; justify-content: center; align-items: center; }
  .admin-frame {
    width: 860px; height: 490px; background: #fff; border-radius: 8px;
    box-shadow: 0 8px 20px rgba(0,0,0,0.15); border: 1px solid #94a3b8;
    display: flex; overflow: hidden;
  }
  .sidebar {
    width: 190px; background: #0f172a; color: #fff; padding: 16px 12px;
    display: flex; flex-direction: column; gap: 8px;
  }
  .side-logo { font-size: 15px; font-weight: bold; color: #38bdf8; margin-bottom: 12px; display: flex; align-items: center; gap: 6px; }
  .side-link {
    font-size: 11.5px; padding: 7px 10px; border-radius: 5px; color: #94a3b8;
    text-decoration: none; display: flex; align-items: center; gap: 8px;
  }
  .side-link.active { background: #1e293b; color: #fff; font-weight: 600; border-left: 3px solid #00A896; }
  .admin-main { flex: 1; display: flex; flex-direction: column; background: #f8fafc; }
  .admin-topbar {
    height: 44px; background: #fff; border-bottom: 1px solid #e2e8f0;
    display: flex; align-items: center; justify-content: space-between; padding: 0 16px;
  }
  .admin-content { flex: 1; padding: 14px; overflow-y: hidden; }
"""

# -------------------------------------------------------------
# 1. Customer Home Dashboard
# -------------------------------------------------------------
home_html = f"""<!DOCTYPE html><html><head><meta charset="utf-8"><style>{MOBILE_CSS}</style></head>
<body>
<div class="phone-frame">
  <div class="status-bar"><span>9:41</span><span>📶 5G  🔋 98%</span></div>
  <div class="app-bar">
    <div class="app-title">🌉 WorkBridge</div>
    <div style="font-size:12px;">📍 Gondal, Rajkot ▾</div>
  </div>
  <div class="screen-content">
    <div style="background: linear-gradient(135deg, #00A896, #0284C7); border-radius: 12px; padding: 12px; color: #fff; margin-bottom: 12px;">
      <div style="font-size: 14px; font-weight: bold;">WorkBridge Flex 🌟</div>
      <div style="font-size: 11px; opacity: 0.9; margin: 3px 0 6px;">10 Monthly Service Credits Available</div>
      <span style="background: rgba(255,255,255,0.25); font-size: 10px; padding: 3px 8px; border-radius: 10px;">50% Renewal Carryover</span>
    </div>

    <div style="font-size: 13px; font-weight: bold; color: #1e293b; margin-bottom: 8px;">Explore Services</div>
    <div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; text-align: center; font-size: 10px;">
      <div style="background: #e0f2fe; padding: 8px 4px; border-radius: 8px;"><div style="font-size: 20px;">🔧</div>Plumbing</div>
      <div style="background: #fef3c7; padding: 8px 4px; border-radius: 8px;"><div style="font-size: 20px;">⚡</div>Electrical</div>
      <div style="background: #f3e8ff; padding: 8px 4px; border-radius: 8px;"><div style="font-size: 20px;">🪚</div>Carpentry</div>
      <div style="background: #fce7f3; padding: 8px 4px; border-radius: 8px;"><div style="font-size: 20px;">🎨</div>Painting</div>
      <div style="background: #d1fae5; padding: 8px 4px; border-radius: 8px;"><div style="font-size: 20px;">🧹</div>Cleaning</div>
      <div style="background: #ccfbf1; padding: 8px 4px; border-radius: 8px;"><div style="font-size: 20px;">❄️</div>AC Repair</div>
      <div style="background: #ffe4e6; padding: 8px 4px; border-radius: 8px;"><div style="font-size: 20px;">💇</div>Salon</div>
      <div style="background: #e0e7ff; padding: 8px 4px; border-radius: 8px;"><div style="font-size: 20px;">🚗</div>Vehicle</div>
    </div>

    <div style="margin-top: 12px; font-size: 13px; font-weight: bold; color: #1e293b;">Top-Rated Karigars</div>
    <div style="background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px; margin-top: 6px; display: flex; align-items: center; justify-content: space-between;">
      <div>
        <div style="font-size: 12px; font-weight: bold;">Ramesh Solanki (Master Plumber)</div>
        <div style="font-size: 10px; color: #64748b;">★ 4.9 (128 reviews) • Verified KYC</div>
      </div>
      <button style="background: #00A896; color: #fff; border: none; padding: 5px 10px; border-radius: 5px; font-size: 10px;">Book</button>
    </div>
  </div>
  <div class="nav-bar">
    <div class="nav-item active">🏠 Home</div>
    <div class="nav-item">📋 Bookings</div>
    <div class="nav-item">🛡️ Safe</div>
    <div class="nav-item">👤 Profile</div>
  </div>
</div>
</body></html>"""
render_screen(home_html, os.path.join(SCREENS_DIR, "screen_home.png"), width=440, height=540)

# -------------------------------------------------------------
# 2. Registration & Login Screens (Side by side)
# -------------------------------------------------------------
auth_html = f"""<!DOCTYPE html><html><head><meta charset="utf-8"><style>
  {MOBILE_CSS}
  body {{ gap: 20px; }}
</style></head>
<body>
<!-- Login Screen -->
<div class="phone-frame">
  <div class="status-bar"><span>9:41</span><span>📶 🔋</span></div>
  <div class="app-bar"><div class="app-title">🌉 WorkBridge Login</div></div>
  <div class="screen-content" style="display:flex; flex-direction:column; justify-content:center; gap: 10px;">
    <div style="text-align:center;">
      <div style="font-size: 26px;">🌉</div>
      <div style="font-size: 15px; font-weight:bold; color: #00A896;">Welcome Back</div>
      <div style="font-size: 10px; color: #64748b;">Sign in to continue</div>
    </div>
    <input style="padding: 9px; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 11px;" value="customer@workbridge.com"/>
    <input style="padding: 9px; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 11px;" type="password" value="••••••••••••"/>
    <button style="background: #00A896; color: #fff; padding: 10px; border:none; border-radius: 6px; font-weight:bold; font-size: 12px;">Sign In</button>
    <div style="text-align:right; font-size: 10px; color: #0284C7;">Forgot Password?</div>
    <div style="text-align:center; font-size: 10px; color: #64748b; margin-top: 10px;">Or log in with Google / OTP</div>
  </div>
</div>

<!-- Register Screen -->
<div class="phone-frame">
  <div class="status-bar"><span>9:41</span><span>📶 🔋</span></div>
  <div class="app-bar"><div class="app-title">Create Account</div></div>
  <div class="screen-content" style="display:flex; flex-direction:column; gap: 8px;">
    <div style="font-size: 13px; font-weight:bold; color: #1e293b;">Join WorkBridge</div>
    <input style="padding: 7px; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 11px;" placeholder="Full Name" value="Henil Mungapara"/>
    <input style="padding: 7px; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 11px;" placeholder="Email Address" value="henil@workbridge.com"/>
    <input style="padding: 7px; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 11px;" placeholder="Phone Number" value="+91 98765 43210"/>
    <select style="padding: 7px; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 11px;">
      <option>Select Role: Customer</option>
      <option>Service Provider (Karigar)</option>
    </select>
    <input style="padding: 7px; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 11px;" type="password" value="••••••••••••"/>
    <button style="background: #00A896; color: #fff; padding: 9px; border:none; border-radius: 6px; font-weight:bold; font-size: 12px; margin-top: 6px;">Register Account</button>
  </div>
</div>
</body></html>"""
render_screen(auth_html, os.path.join(SCREENS_DIR, "screen_auth.png"), width=860, height=540)

# -------------------------------------------------------------
# 3. Forgot Password & Email Verification Screens
# -------------------------------------------------------------
pwd_html = f"""<!DOCTYPE html><html><head><meta charset="utf-8"><style>
  {MOBILE_CSS}
  body {{ gap: 20px; }}
</style></head>
<body>
<div class="phone-frame">
  <div class="status-bar"><span>9:41</span><span>📶 🔋</span></div>
  <div class="app-bar"><div class="app-title">Reset Password</div></div>
  <div class="screen-content" style="display:flex; flex-direction:column; justify-content:center; gap: 12px;">
    <div style="text-align:center;">
      <div style="font-size: 28px;">🔐</div>
      <div style="font-size: 14px; font-weight:bold; color: #1e293b;">Forgot Password</div>
      <div style="font-size: 10px; color: #64748b; padding: 0 10px;">Enter your registered email address to receive secure OTP</div>
    </div>
    <input style="padding: 9px; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 11px;" value="henil@workbridge.com"/>
    <button style="background: #00A896; color: #fff; padding: 10px; border:none; border-radius: 6px; font-weight:bold; font-size: 12px;">Send OTP Code</button>
  </div>
</div>

<div class="phone-frame">
  <div class="status-bar"><span>9:41</span><span>📶 🔋</span></div>
  <div class="app-bar"><div class="app-title">Verify OTP Code</div></div>
  <div class="screen-content" style="display:flex; flex-direction:column; justify-content:center; gap: 12px; text-align:center;">
    <div style="font-size: 28px;">📩</div>
    <div style="font-size: 14px; font-weight:bold; color: #1e293b;">OTP Sent to Email</div>
    <div style="font-size: 10.5px; color: #64748b;">Code sent to henil@workbridge.com</div>
    <div style="display:flex; justify-content:center; gap: 8px;">
      <input style="width: 32px; height: 36px; text-align:center; font-size: 16px; font-weight:bold; border: 1px solid #00A896; border-radius: 6px;" value="5"/>
      <input style="width: 32px; height: 36px; text-align:center; font-size: 16px; font-weight:bold; border: 1px solid #00A896; border-radius: 6px;" value="8"/>
      <input style="width: 32px; height: 36px; text-align:center; font-size: 16px; font-weight:bold; border: 1px solid #00A896; border-radius: 6px;" value="2"/>
      <input style="width: 32px; height: 36px; text-align:center; font-size: 16px; font-weight:bold; border: 1px solid #00A896; border-radius: 6px;" value="9"/>
    </div>
    <button style="background: #00A896; color: #fff; padding: 10px; border:none; border-radius: 6px; font-weight:bold; font-size: 12px;">Verify &amp; Set New Password</button>
  </div>
</div>
</body></html>"""
render_screen(pwd_html, os.path.join(SCREENS_DIR, "screen_password.png"), width=860, height=540)

# -------------------------------------------------------------
# 4. Service Categories & Catalog Screen
# -------------------------------------------------------------
catalog_html = f"""<!DOCTYPE html><html><head><meta charset="utf-8"><style>{MOBILE_CSS}</style></head>
<body>
<div class="phone-frame">
  <div class="status-bar"><span>9:41</span><span>📶 🔋</span></div>
  <div class="app-bar">
    <div class="app-title">Service Categories</div>
    <div style="font-size:12px;">🔍 Filter</div>
  </div>
  <div class="screen-content">
    <div style="font-size: 11px; color: #64748b; margin-bottom: 8px;">8 Certified On-Demand Trade Categories</div>
    <div style="display: flex; flex-direction: column; gap: 8px;">
      <div style="background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 10px; display:flex; align-items:center; gap: 10px;">
        <div style="font-size: 24px; background: #e0f2fe; padding: 8px; border-radius: 8px;">🔧</div>
        <div style="flex:1;">
          <div style="font-size: 12px; font-weight:bold;">Plumbing Services</div>
          <div style="font-size: 10px; color: #64748b;">Pipe leak repairs, bathroom fittings &amp; drain cleaning</div>
        </div>
        <div style="font-size: 11px; font-weight:bold; color: #00A896;">38 Active</div>
      </div>

      <div style="background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 10px; display:flex; align-items:center; gap: 10px;">
        <div style="font-size: 24px; background: #fef3c7; padding: 8px; border-radius: 8px;">⚡</div>
        <div style="flex:1;">
          <div style="font-size: 12px; font-weight:bold;">Electrical Works</div>
          <div style="font-size: 10px; color: #64748b;">Wiring, fixtures, switches &amp; circuit diagnostics</div>
        </div>
        <div style="font-size: 11px; font-weight:bold; color: #00A896;">42 Active</div>
      </div>

      <div style="background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 10px; display:flex; align-items:center; gap: 10px;">
        <div style="font-size: 24px; background: #f3e8ff; padding: 8px; border-radius: 8px;">🪚</div>
        <div style="flex:1;">
          <div style="font-size: 12px; font-weight:bold;">Carpentry &amp; Woodwork</div>
          <div style="font-size: 10px; color: #64748b;">Furniture repair, lock installation &amp; modular cabinets</div>
        </div>
        <div style="font-size: 11px; font-weight:bold; color: #00A896;">25 Active</div>
      </div>

      <div style="background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 10px; display:flex; align-items:center; gap: 10px;">
        <div style="font-size: 24px; background: #ccfbf1; padding: 8px; border-radius: 8px;">❄️</div>
        <div style="flex:1;">
          <div style="font-size: 12px; font-weight:bold;">AC &amp; Appliance Repair</div>
          <div style="font-size: 10px; color: #64748b;">AC gas filling, servicing, washing machines &amp; fridge</div>
        </div>
        <div style="font-size: 11px; font-weight:bold; color: #00A896;">29 Active</div>
      </div>
    </div>
  </div>
</div>
</body></html>"""
render_screen(catalog_html, os.path.join(SCREENS_DIR, "screen_catalog.png"), width=440, height=540)

# -------------------------------------------------------------
# 5. Service & Professional Details Screen
# -------------------------------------------------------------
provider_detail_html = f"""<!DOCTYPE html><html><head><meta charset="utf-8"><style>{MOBILE_CSS}</style></head>
<body>
<div class="phone-frame">
  <div class="status-bar"><span>9:41</span><span>📶 🔋</span></div>
  <div class="app-bar">
    <div class="app-title">Professional Profile</div>
    <div style="font-size:12px;">★ 4.9</div>
  </div>
  <div class="screen-content">
    <div style="text-align:center; background:#fff; border-radius:10px; padding: 12px; border:1px solid #e2e8f0;">
      <div style="font-size: 40px; margin-bottom: 4px;">🧑‍🔧</div>
      <div style="font-size: 14px; font-weight:bold; color: #1e293b;">Ramesh Solanki</div>
      <div style="font-size: 11px; color: #00A896; font-weight:600;">Verified Master Technician (Plumbing)</div>
      <div style="font-size: 10px; color: #64748b; margin-top: 4px;">Govt ID Verified • Police Clearance Passed</div>
    </div>

    <div style="display:grid; grid-template-columns: repeat(3, 1fr); gap: 6px; margin: 10px 0; text-align:center;">
      <div style="background:#fff; padding:6px; border-radius:6px; border:1px solid #e2e8f0;">
        <div style="font-size:12px; font-weight:bold; color:#00A896;">340+</div>
        <div style="font-size:9px; color:#64748b;">Jobs Done</div>
      </div>
      <div style="background:#fff; padding:6px; border-radius:6px; border:1px solid #e2e8f0;">
        <div style="font-size:12px; font-weight:bold; color:#f59e0b;">4.9 ★</div>
        <div style="font-size:9px; color:#64748b;">128 Reviews</div>
      </div>
      <div style="background:#fff; padding:6px; border-radius:6px; border:1px solid #e2e8f0;">
        <div style="font-size:12px; font-weight:bold; color:#2563eb;">8 yrs</div>
        <div style="font-size:9px; color:#64748b;">Experience</div>
      </div>
    </div>

    <div style="font-size: 12px; font-weight:bold; color: #1e293b; margin-bottom: 4px;">Specializations</div>
    <div style="font-size: 10.5px; color: #475569; background:#fff; padding:8px; border-radius:6px; border:1px solid #e2e8f0; line-height:1.4;">
      Bathroom fittings, Concealed pipeline leakage detection, Overhead tank cleaning, Water pump installation.
    </div>

    <button style="width:100%; background: #00A896; color: #fff; padding: 10px; border:none; border-radius: 6px; font-weight:bold; font-size: 12px; margin-top: 12px;">
      Hire Ramesh Solanki Directly
    </button>
  </div>
</div>
</body></html>"""
render_screen(provider_detail_html, os.path.join(SCREENS_DIR, "screen_provider_details.png"), width=440, height=540)

# -------------------------------------------------------------
# 6. Booking Modal: Broadcast vs Specific Karigar
# -------------------------------------------------------------
booking_modal_html = f"""<!DOCTYPE html><html><head><meta charset="utf-8"><style>
  {MOBILE_CSS}
  body {{ gap: 20px; }}
</style></head>
<body>
<!-- Modal 1: Dispatch Choice -->
<div class="phone-frame">
  <div class="status-bar"><span>9:41</span><span>📶 🔋</span></div>
  <div class="app-bar"><div class="app-title">Select Booking Mode</div></div>
  <div class="screen-content" style="display:flex; flex-direction:column; gap: 10px;">
    <div style="font-size: 12px; font-weight:bold; color: #1e293b;">Choose Dispatch Type:</div>

    <div style="background: #e6fffa; border: 2px solid #00A896; border-radius: 8px; padding: 10px;">
      <div style="font-size: 12px; font-weight:bold; color: #00A896;">⚡ Broadcast (Random Karigar)</div>
      <div style="font-size: 10px; color: #475569; margin: 3px 0;">Alerts all nearest verified technicians instantly. Fastest response within 5-10 mins.</div>
      <div style="font-size: 10px; font-weight:bold; color: #0f766e;">Recommended for Emergencies</div>
    </div>

    <div style="background: #fff; border: 1px solid #cbd5e1; border-radius: 8px; padding: 10px;">
      <div style="font-size: 12px; font-weight:bold; color: #1e293b;">🎯 Specific Professional</div>
      <div style="font-size: 10px; color: #475569; margin: 3px 0;">Directly hire your preferred technician based on ratings, portfolio and past service history.</div>
    </div>

    <div style="font-size: 11px; font-weight:bold; color: #1e293b; margin-top: 6px;">Service Details</div>
    <input style="padding: 7px; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 10.5px;" value="Kitchen Sink Pipe Leakage Repair"/>
    <textarea style="padding: 7px; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 10px; height: 50px;">Major leak under the sink cabinet, urgent repair needed.</textarea>
  </div>
</div>

<!-- Modal 2: Schedule & Address -->
<div class="phone-frame">
  <div class="status-bar"><span>9:41</span><span>📶 🔋</span></div>
  <div class="app-bar"><div class="app-title">Schedule &amp; Confirm</div></div>
  <div class="screen-content" style="display:flex; flex-direction:column; gap: 10px;">
    <div style="font-size: 12px; font-weight:bold; color: #1e293b;">Select Schedule</div>
    <div style="display:flex; gap: 8px;">
      <div style="flex:1; background:#00A896; color:#fff; text-align:center; padding:8px; border-radius:6px; font-size:11px; font-weight:bold;">Today, 26 Oct</div>
      <div style="flex:1; background:#fff; border:1px solid #cbd5e1; text-align:center; padding:8px; border-radius:6px; font-size:11px;">Tomorrow</div>
    </div>
    <div style="display:grid; grid-template-columns: repeat(3, 1fr); gap: 6px; font-size: 10px; text-align:center;">
      <div style="background:#fff; border:1px solid #cbd5e1; padding:6px; border-radius:5px;">10:00 AM</div>
      <div style="background:#e0f2fe; border:1px solid #0284C7; color:#0284C7; font-weight:bold; padding:6px; border-radius:5px;">02:30 PM</div>
      <div style="background:#fff; border:1px solid #cbd5e1; padding:6px; border-radius:5px;">05:00 PM</div>
    </div>

    <div style="font-size: 12px; font-weight:bold; color: #1e293b; margin-top: 4px;">Service Location</div>
    <div style="background:#fff; border:1px solid #cbd5e1; padding:8px; border-radius:6px; font-size:10px;">
      📍 104, Sunrise Heights, Near College Road, Gondal (GPS Active)
    </div>

    <div style="background:#f1f5f9; padding:8px; border-radius:6px; display:flex; justify-content:space-between; font-size:11px; font-weight:bold;">
      <span>Estimated Cost:</span>
      <span style="color:#00A896;">₹350 - ₹500</span>
    </div>

    <button style="background: #00A896; color: #fff; padding: 10px; border:none; border-radius: 6px; font-weight:bold; font-size: 12px;">Confirm &amp; Dispatch Job</button>
  </div>
</div>
</body></html>"""
render_screen(booking_modal_html, os.path.join(SCREENS_DIR, "screen_booking_modal.png"), width=860, height=540)

# -------------------------------------------------------------
# 7. Checkout & Online Payment (Razorpay) Screen
# -------------------------------------------------------------
checkout_html = f"""<!DOCTYPE html><html><head><meta charset="utf-8"><style>
  {MOBILE_CSS}
  body {{ gap: 20px; }}
</style></head>
<body>
<!-- Checkout -->
<div class="phone-frame">
  <div class="status-bar"><span>9:41</span><span>📶 🔋</span></div>
  <div class="app-bar"><div class="app-title">Booking Summary</div></div>
  <div class="screen-content" style="display:flex; flex-direction:column; gap: 8px;">
    <div style="background:#fff; border:1px solid #e2e8f0; border-radius:8px; padding:10px; font-size:11px;">
      <div style="font-weight:bold; color:#1e293b; font-size:12px;">Plumbing Inspection &amp; Fitting</div>
      <div style="color:#64748b; font-size:10px;">Booking #WB-84920 • 26 Oct, 2:30 PM</div>
      <hr style="border:none; border-top:1px solid #f1f5f9; margin:6px 0;"/>
      <div style="display:flex; justify-content:space-between; margin-bottom:3px;"><span>Service Charge:</span><span>₹450.00</span></div>
      <div style="display:flex; justify-content:space-between; margin-bottom:3px;"><span>Safety &amp; Platform Fee:</span><span>₹30.00</span></div>
      <div style="display:flex; justify-content:space-between; margin-bottom:3px; color:#16a34a;"><span>Flex Member Discount:</span><span>- ₹50.00</span></div>
      <hr style="border:none; border-top:1px solid #cbd5e1; margin:6px 0;"/>
      <div style="display:flex; justify-content:space-between; font-weight:bold; font-size:12px;"><span>Total Payable:</span><span style="color:#00A896;">₹430.00</span></div>
    </div>

    <div style="font-size:11px; font-weight:bold; color:#1e293b;">Select Payment Option:</div>
    <div style="background:#f0fdfa; border:1px solid #00A896; border-radius:6px; padding:8px; font-size:10.5px; font-weight:bold; color:#0f766e;">
      💳 Online Payment (UPI, Cards, NetBanking via Razorpay)
    </div>
    <div style="background:#fff; border:1px solid #cbd5e1; border-radius:6px; padding:8px; font-size:10.5px;">
      💵 Cash on Service Delivery
    </div>
    <div style="background:#fff; border:1px solid #cbd5e1; border-radius:6px; padding:8px; font-size:10.5px;">
      🌟 WorkBridge Flex Credit (1 credit = ₹100)
    </div>

    <button style="background: #00A896; color: #fff; padding: 10px; border:none; border-radius: 6px; font-weight:bold; font-size: 12px; margin-top:8px;">
      Proceed to Pay ₹430
    </button>
  </div>
</div>

<!-- Razorpay Modal -->
<div class="phone-frame">
  <div class="status-bar"><span>9:41</span><span>📶 🔋</span></div>
  <div style="height:35px; background:#0c2340; color:#fff; display:flex; align-items:center; justify-content:space-between; padding:0 12px; font-size:12px; font-weight:bold;">
    <span>Razorpay Trusted</span><span>₹430.00</span>
  </div>
  <div class="screen-content" style="background:#f1f5f9; display:flex; flex-direction:column; gap:8px;">
    <div style="background:#fff; border-radius:8px; padding:10px; border:1px solid #cbd5e1;">
      <div style="font-size:11px; font-weight:bold; color:#334155; margin-bottom:6px;">Preferred Payment Methods</div>
      <div style="display:flex; flex-direction:column; gap:6px; font-size:10.5px;">
        <div style="padding:6px; border:1px solid #e2e8f0; border-radius:4px; display:flex; justify-content:space-between;"><span>Google Pay / PhonePe UPI</span><span style="color:#16a34a;">Fast</span></div>
        <div style="padding:6px; border:1px solid #e2e8f0; border-radius:4px;">Credit / Debit Card</div>
        <div style="padding:6px; border:1px solid #e2e8f0; border-radius:4px;">Net Banking (HDFC, SBI, ICICI)</div>
        <div style="padding:6px; border:1px solid #e2e8f0; border-radius:4px;">Paytm Wallet</div>
      </div>
    </div>
    <button style="background: #2563eb; color: #fff; padding: 9px; border:none; border-radius: 6px; font-weight:bold; font-size: 11px;">
      🔒 Pay Securely ₹430
    </button>
  </div>
</div>
</body></html>"""
render_screen(checkout_html, os.path.join(SCREENS_DIR, "screen_checkout.png"), width=860, height=540)

# -------------------------------------------------------------
# 8. Customer Profile & Bookings List Screen
# -------------------------------------------------------------
profile_html = f"""<!DOCTYPE html><html><head><meta charset="utf-8"><style>
  {MOBILE_CSS}
  body {{ gap: 20px; }}
</style></head>
<body>
<!-- Customer Profile -->
<div class="phone-frame">
  <div class="status-bar"><span>9:41</span><span>📶 🔋</span></div>
  <div class="app-bar"><div class="app-title">My Profile</div></div>
  <div class="screen-content">
    <div style="background:#fff; border-radius:8px; padding:12px; border:1px solid #e2e8f0; text-align:center; margin-bottom:10px;">
      <div style="font-size:36px;">👤</div>
      <div style="font-size:13px; font-weight:bold;">Henil Mungapara</div>
      <div style="font-size:10px; color:#64748b;">henil@workbridge.com • +91 98765 43210</div>
      <div style="margin-top:6px;"><span style="background:#e0f2fe; color:#0284C7; font-size:9.5px; padding:2px 8px; border-radius:10px; font-weight:bold;">Verified Member</span></div>
    </div>

    <div style="display:flex; flex-direction:column; gap:6px; font-size:11px;">
      <div style="background:#fff; padding:8px 10px; border-radius:6px; border:1px solid #e2e8f0;">🏠 Saved Addresses (2)</div>
      <div style="background:#fff; padding:8px 10px; border-radius:6px; border:1px solid #e2e8f0;">🌟 WorkBridge Flex Membership (Active)</div>
      <div style="background:#fff; padding:8px 10px; border-radius:6px; border:1px solid #e2e8f0;">🛡️ Trusted Emergency Contacts</div>
      <div style="background:#fff; padding:8px 10px; border-radius:6px; border:1px solid #e2e8f0;">🔒 Change Password</div>
      <div style="background:#fff; padding:8px 10px; border-radius:6px; border:1px solid #e2e8f0; color:#ef4444;">🚪 Sign Out</div>
    </div>
  </div>
</div>

<!-- My Bookings List -->
<div class="phone-frame">
  <div class="status-bar"><span>9:41</span><span>📶 🔋</span></div>
  <div class="app-bar"><div class="app-title">My Bookings</div></div>
  <div class="screen-content">
    <div style="display:flex; gap:6px; margin-bottom:8px; font-size:10px;">
      <span style="background:#00A896; color:#fff; padding:3px 8px; border-radius:12px; font-weight:bold;">All</span>
      <span style="background:#e2e8f0; padding:3px 8px; border-radius:12px;">Active (1)</span>
      <span style="background:#e2e8f0; padding:3px 8px; border-radius:12px;">Completed</span>
    </div>

    <div style="display:flex; flex-direction:column; gap:8px;">
      <!-- Active Booking -->
      <div style="background:#fff; border-left:4px solid #00A896; border-radius:6px; padding:8px; border:1px solid #e2e8f0; font-size:10.5px;">
        <div style="display:flex; justify-content:space-between; font-weight:bold;">
          <span>Kitchen Sink Pipe Repair</span>
          <span style="color:#00A896;">Accepted</span>
        </div>
        <div style="font-size:9.5px; color:#64748b;">Karigar: Ramesh Solanki • 26 Oct, 2:30 PM</div>
        <div style="margin-top:6px; display:flex; justify-content:space-between; align-items:center;">
          <span style="font-weight:bold; color:#1e293b;">₹430</span>
          <button style="background:#0284C7; color:#fff; border:none; padding:4px 8px; border-radius:4px; font-size:9.5px;">Live Track 📍</button>
        </div>
      </div>

      <!-- Completed Booking -->
      <div style="background:#fff; border-left:4px solid #16a34a; border-radius:6px; padding:8px; border:1px solid #e2e8f0; font-size:10.5px;">
        <div style="display:flex; justify-content:space-between; font-weight:bold;">
          <span>Ceiling Fan Motor Rewiring</span>
          <span style="color:#16a34a;">Completed</span>
        </div>
        <div style="font-size:9.5px; color:#64748b;">Karigar: Amit Dave • 22 Oct, 11:00 AM</div>
        <div style="margin-top:6px; display:flex; justify-content:space-between; align-items:center;">
          <span style="font-weight:bold; color:#1e293b;">₹250</span>
          <span style="font-size:9px; color:#f59e0b;">★ 5.0 Rated</span>
        </div>
      </div>
    </div>
  </div>
</div>
</body></html>"""
render_screen(profile_html, os.path.join(SCREENS_DIR, "screen_profile.png"), width=860, height=540)

# -------------------------------------------------------------
# 9. Booking Details & Status Lifecycle Timeline Screen
# -------------------------------------------------------------
lifecycle_html = f"""<!DOCTYPE html><html><head><meta charset="utf-8"><style>{MOBILE_CSS}</style></head>
<body>
<div class="phone-frame">
  <div class="status-bar"><span>9:41</span><span>📶 🔋</span></div>
  <div class="app-bar">
    <div class="app-title">Booking #WB-84920</div>
    <div style="font-size:11px; background:#e6fffa; color:#00A896; padding:2px 6px; border-radius:4px; font-weight:bold;">In Progress</div>
  </div>
  <div class="screen-content">
    <div style="background:#fff; border-radius:8px; padding:10px; border:1px solid #e2e8f0; margin-bottom:8px;">
      <div style="font-size:12px; font-weight:bold; color:#1e293b;">Kitchen Sink Pipe Leakage Repair</div>
      <div style="font-size:10px; color:#64748b;">Scheduled: 26 Oct 2026 at 02:30 PM</div>
      <div style="font-size:10px; color:#64748b;">Customer: Henil Mungapara (Gondal)</div>
    </div>

    <div style="font-size:11px; font-weight:bold; color:#1e293b; margin-bottom:6px;">Booking Status Timeline</div>
    <div style="background:#fff; border-radius:8px; padding:10px; border:1px solid #e2e8f0; font-size:10px; display:flex; flex-direction:column; gap:8px;">
      <div style="display:flex; align-items:center; gap:8px; color:#16a34a; font-weight:bold;">
        <span>✓</span> 1. Request Created (02:05 PM)
      </div>
      <div style="display:flex; align-items:center; gap:8px; color:#16a34a; font-weight:bold;">
        <span>✓</span> 2. Karigar Assigned: Ramesh Solanki (02:08 PM)
      </div>
      <div style="display:flex; align-items:center; gap:8px; color:#16a34a; font-weight:bold;">
        <span>✓</span> 3. Technician En-Route (Live GPS Active) (02:15 PM)
      </div>
      <div style="display:flex; align-items:center; gap:8px; color:#00A896; font-weight:bold;">
        <span>●</span> 4. Technician Arrived &amp; Service In-Progress (02:32 PM)
      </div>
      <div style="display:flex; align-items:center; gap:8px; color:#94a3b8;">
        <span>○</span> 5. Service Completion &amp; Review
      </div>
    </div>

    <div style="background:#fff; border-radius:8px; padding:8px; border:1px solid #e2e8f0; margin-top:8px; display:flex; justify-content:space-between; align-items:center;">
      <div>
        <div style="font-size:11px; font-weight:bold;">Ramesh Solanki</div>
        <div style="font-size:9.5px; color:#64748b;">📞 +91 98250 11223</div>
      </div>
      <button style="background:#00A896; color:#fff; border:none; padding:5px 10px; border-radius:4px; font-size:10px;">Call Karigar</button>
    </div>
  </div>
</div>
</body></html>"""
render_screen(lifecycle_html, os.path.join(SCREENS_DIR, "screen_lifecycle.png"), width=440, height=540)

# -------------------------------------------------------------
# 10. Live Geolocation Tracking Map Screen
# -------------------------------------------------------------
tracking_map_html = f"""<!DOCTYPE html><html><head><meta charset="utf-8"><style>{MOBILE_CSS}</style></head>
<body>
<div class="phone-frame">
  <div class="status-bar"><span>9:41</span><span>📶 🔋</span></div>
  <div class="app-bar">
    <div class="app-title">Live Technician Tracking</div>
    <div style="font-size:11px; color:#fef08a;">12 mins away</div>
  </div>
  <div class="screen-content" style="padding:0; position:relative; background:#e5e7eb;">
    <!-- Mock Map Canvas -->
    <svg width="100%" height="100%">
      <!-- Road network -->
      <rect width="100%" height="100%" fill="#f1f5f9"/>
      <path d="M 0 100 Q 150 120 380 90" stroke="#cbd5e1" stroke-width="16" fill="none"/>
      <path d="M 80 0 L 100 400" stroke="#cbd5e1" stroke-width="14" fill="none"/>
      <path d="M 280 0 L 260 400" stroke="#cbd5e1" stroke-width="14" fill="none"/>
      <path d="M 0 260 L 380 270" stroke="#cbd5e1" stroke-width="18" fill="none"/>

      <!-- Route Polyline -->
      <path d="M 95 105 L 180 110 L 270 200 L 265 265" stroke="#0284C7" stroke-width="4" stroke-dasharray="6,4" fill="none"/>

      <!-- Destination Pin (Customer) -->
      <circle cx="265" cy="265" r="10" fill="#ef4444"/>
      <circle cx="265" cy="265" r="4" fill="#fff"/>
      <text x="210" y="300" font-size="11" font-weight="bold" fill="#1e293b">Your Home (Gondal)</text>

      <!-- Provider Pin (Karigar en-route) -->
      <circle cx="95" cy="105" r="14" fill="#00A896"/>
      <circle cx="95" cy="105" r="6" fill="#fff"/>
      <text x="50" y="85" font-size="11" font-weight="bold" fill="#0f766e">Ramesh (En-Route)</text>
    </svg>

    <!-- Floating Tracking Card -->
    <div style="position:absolute; bottom:10px; left:10px; right:10px; background:#fff; border-radius:12px; padding:10px; box-shadow:0 4px 12px rgba(0,0,0,0.15); border:1px solid #cbd5e1;">
      <div style="display:flex; justify-content:space-between; align-items:center;">
        <div>
          <div style="font-size:12px; font-weight:bold;">Estimated Arrival: 02:27 PM</div>
          <div style="font-size:10px; color:#64748b;">Distance: 1.8 km • Real-time GPS stream</div>
        </div>
        <button style="background:#16a34a; color:#fff; border:none; padding:6px 10px; border-radius:6px; font-size:10px; font-weight:bold;">Call Karigar</button>
      </div>
    </div>
  </div>
</div>
</body></html>"""
render_screen(tracking_map_html, os.path.join(SCREENS_DIR, "screen_tracking_map.png"), width=440, height=540)

# -------------------------------------------------------------
# 11. WorkBridge Flex Membership Screen
# -------------------------------------------------------------
flex_html = f"""<!DOCTYPE html><html><head><meta charset="utf-8"><style>{MOBILE_CSS}</style></head>
<body>
<div class="phone-frame">
  <div class="status-bar"><span>9:41</span><span>📶 🔋</span></div>
  <div class="app-bar">
    <div class="app-title">WorkBridge Flex</div>
    <div style="font-size:11px; background:#fff; color:#00A896; padding:2px 6px; border-radius:4px; font-weight:bold;">Active Plan</div>
  </div>
  <div class="screen-content">
    <div style="background:linear-gradient(135deg, #0f172a, #1e3a8a); color:#fff; border-radius:12px; padding:14px; margin-bottom:10px;">
      <div style="font-size:11px; color:#38bdf8; font-weight:bold; letter-spacing:0.5px;">ANNUAL FLEX MEMBERSHIP</div>
      <div style="font-size:22px; font-weight:bold; margin:6px 0;">8 Credits Remaining</div>
      <div style="font-size:10px; opacity:0.85;">10 Credits / Month • 120 Credits / Year</div>
      <div style="margin-top:10px; background:rgba(255,255,255,0.15); border-radius:6px; height:8px; overflow:hidden;">
        <div style="width:80%; height:100%; background:#38bdf8;"></div>
      </div>
    </div>

    <div style="background:#fff; border-radius:8px; padding:10px; border:1px solid #e2e8f0; margin-bottom:8px;">
      <div style="font-size:12px; font-weight:bold; color:#1e293b;">Renewal Carryover Rule</div>
      <div style="font-size:10px; color:#64748b; margin-top:3px; line-height:1.4;">
        At cycle renewal, <b>50% of unused eligible credits</b> automatically roll over to the next cycle. Never lose your loyalty benefits!
      </div>
    </div>

    <div style="background:#fff; border-radius:8px; padding:10px; border:1px solid #e2e8f0;">
      <div style="font-size:12px; font-weight:bold; color:#1e293b;">WorkBridge Share 🤝</div>
      <div style="font-size:10px; color:#64748b; margin-top:3px; line-height:1.4;">
        Transfer or book an eligible service credit for family or friends living at another address.
      </div>
      <button style="background:#0284C7; color:#fff; border:none; padding:6px 12px; border-radius:5px; font-size:10px; font-weight:bold; margin-top:8px;">Share Service With Family</button>
    </div>
  </div>
</div>
</body></html>"""
render_screen(flex_html, os.path.join(SCREENS_DIR, "screen_flex.png"), width=440, height=540)

# -------------------------------------------------------------
# 12. WorkBridge Safe SOS Emergency Safety Screen
# -------------------------------------------------------------
safe_html = f"""<!DOCTYPE html><html><head><meta charset="utf-8"><style>{MOBILE_CSS}</style></head>
<body>
<div class="phone-frame">
  <div class="status-bar"><span>9:41</span><span>📶 🔋</span></div>
  <div class="app-bar" style="background:#dc2626;">
    <div class="app-title">🛡️ WorkBridge Safe</div>
    <div style="font-size:11px;">Active Service</div>
  </div>
  <div class="screen-content" style="text-align:center; display:flex; flex-direction:column; justify-content:center; align-items:center; gap:12px;">
    <div style="font-size:14px; font-weight:bold; color:#991b1b;">In-Home Emergency Safety Protocol</div>
    <div style="font-size:10.5px; color:#64748b; padding:0 15px;">
      Press and hold the button below for 3 seconds if you feel unsafe. It will immediately trigger emergency calling and notify your trusted contacts.
    </div>

    <!-- SOS Button -->
    <div style="width:110px; height:110px; border-radius:50%; background:#ef4444; border:6px solid #fecaca; display:flex; flex-direction:column; align-items:center; justify-content:center; color:#fff; box-shadow:0 8px 20px rgba(239,68,68,0.4); cursor:pointer;">
      <div style="font-size:26px;">⚠️</div>
      <div style="font-size:14px; font-weight:bold; margin-top:2px;">HOLD SOS</div>
      <div style="font-size:8px;">3 SECONDS</div>
    </div>

    <div style="background:#fff; border-radius:8px; padding:10px; border:1px solid #fecaca; width:100%; text-align:left; font-size:10px; line-height:1.4;">
      <div style="font-weight:bold; color:#dc2626; margin-bottom:3px;">Automated Safety Actions:</div>
      <div>• Connects call to Emergency Police (112)</div>
      <div>• Sends live GPS &amp; Karigar details to Trusted Contact (+91 99000 11222)</div>
      <div>• Alerts 24/7 WorkBridge Emergency Safety Operations Center</div>
      <div>• Logs permanent immutable incident record in Firestore</div>
    </div>
  </div>
</div>
</body></html>"""
render_screen(safe_html, os.path.join(SCREENS_DIR, "screen_safe.png"), width=440, height=540)

# -------------------------------------------------------------
# 13. Admin Executive Dashboard Screen
# -------------------------------------------------------------
admin_dashboard_html = f"""<!DOCTYPE html><html><head><meta charset="utf-8"><style>{ADMIN_CSS}</style></head>
<body>
<div class="admin-frame">
  <div class="sidebar">
    <div class="side-logo">🌉 WorkBridge Admin</div>
    <div class="side-link active">📊 Dashboard</div>
    <div class="side-link">👥 Customers</div>
    <div class="side-link">🧑‍🔧 Service Providers</div>
    <div class="side-link">📂 Categories</div>
    <div class="side-link">📋 Bookings</div>
    <div class="side-link">💳 Payments</div>
    <div class="side-link">🛡️ Safety Incidents</div>
    <div class="side-link">⚙️ Store Settings</div>
  </div>
  <div class="admin-main">
    <div class="admin-topbar">
      <div style="font-size:13px; font-weight:bold; color:#1e293b;">Executive Overview Dashboard</div>
      <div style="font-size:11px; color:#64748b;">Super Admin: Henil Mungapara | Rajkot Region</div>
    </div>
    <div class="admin-content">
      <!-- KPI Stats Grid -->
      <div style="display:grid; grid-template-columns: repeat(4, 1fr); gap:10px; margin-bottom:12px;">
        <div style="background:#fff; border:1px solid #e2e8f0; border-radius:6px; padding:10px;">
          <div style="font-size:10px; color:#64748b;">Total Platform Revenue</div>
          <div style="font-size:16px; font-weight:bold; color:#00A896;">₹4,369,109</div>
          <div style="font-size:9px; color:#16a34a;">↑ 18.4% from last month</div>
        </div>
        <div style="background:#fff; border:1px solid #e2e8f0; border-radius:6px; padding:10px;">
          <div style="font-size:10px; color:#64748b;">Completed Gigs</div>
          <div style="font-size:16px; font-weight:bold; color:#0284C7;">3,428</div>
          <div style="font-size:9px; color:#64748b;">99.2% satisfaction rate</div>
        </div>
        <div style="background:#fff; border:1px solid #e2e8f0; border-radius:6px; padding:10px;">
          <div style="font-size:10px; color:#64748b;">Verified Karigars</div>
          <div style="font-size:16px; font-weight:bold; color:#f59e0b;">186</div>
          <div style="font-size:9px; color:#64748b;">14 KYC pending</div>
        </div>
        <div style="background:#fff; border:1px solid #e2e8f0; border-radius:6px; padding:10px;">
          <div style="font-size:10px; color:#64748b;">WorkBridge Safe Incidents</div>
          <div style="font-size:16px; font-weight:bold; color:#ef4444;">0 Active</div>
          <div style="font-size:9px; color:#16a34a;">100% resolved safely</div>
        </div>
      </div>

      <!-- Live Gigs Table -->
      <div style="background:#fff; border:1px solid #e2e8f0; border-radius:6px; padding:10px;">
        <div style="font-size:12px; font-weight:bold; color:#1e293b; margin-bottom:8px;">Live Active Service Gigs</div>
        <table style="width:100%; border-collapse:collapse; font-size:10.5px; text-align:left;">
          <tr style="background:#f8fafc; border-bottom:1px solid #e2e8f0;">
            <th style="padding:5px;">Booking ID</th>
            <th>Customer</th>
            <th>Technician</th>
            <th>Trade</th>
            <th>Amount</th>
            <th>Status</th>
            <th>Action</th>
          </tr>
          <tr style="border-bottom:1px solid #f1f5f9;">
            <td style="padding:6px 5px; font-weight:bold;">#WB-84920</td>
            <td>Henil M.</td>
            <td>Ramesh Solanki</td>
            <td>Plumbing</td>
            <td>₹430</td>
            <td><span style="background:#e0f2fe; color:#0284C7; padding:2px 6px; border-radius:4px; font-size:9px;">In-Progress</span></td>
            <td><button style="background:#00A896; color:#fff; border:none; padding:3px 6px; border-radius:3px; font-size:9px;">Track GPS</button></td>
          </tr>
          <tr style="border-bottom:1px solid #f1f5f9;">
            <td style="padding:6px 5px; font-weight:bold;">#WB-84919</td>
            <td>Ayush P.</td>
            <td>Amit Dave</td>
            <td>Electrical</td>
            <td>₹650</td>
            <td><span style="background:#fef3c7; color:#b45309; padding:2px 6px; border-radius:4px; font-size:9px;">En-Route</span></td>
            <td><button style="background:#00A896; color:#fff; border:none; padding:3px 6px; border-radius:3px; font-size:9px;">Track GPS</button></td>
          </tr>
          <tr>
            <td style="padding:6px 5px; font-weight:bold;">#WB-84918</td>
            <td>Jenil V.</td>
            <td>Kishore Bhai</td>
            <td>Carpentry</td>
            <td>₹1,200</td>
            <td><span style="background:#dcfce7; color:#15803d; padding:2px 6px; border-radius:4px; font-size:9px;">Completed</span></td>
            <td><button style="background:#64748b; color:#fff; border:none; padding:3px 6px; border-radius:3px; font-size:9px;">Audit</button></td>
          </tr>
        </table>
      </div>
    </div>
  </div>
</div>
</body></html>"""
render_screen(admin_dashboard_html, os.path.join(SCREENS_DIR, "screen_admin_dashboard.png"), width=880, height=520)

# -------------------------------------------------------------
# 14. Admin Data Management Screen (from codebase)
# -------------------------------------------------------------
admin_data_html = f"""<!DOCTYPE html><html><head><meta charset="utf-8"><style>{ADMIN_CSS}</style></head>
<body>
<div class="admin-frame">
  <div class="sidebar">
    <div class="side-logo">🌉 WorkBridge Admin</div>
    <div class="side-link">📊 Dashboard</div>
    <div class="side-link active">⚙️ Data Hub</div>
    <div class="side-link">👥 Customers</div>
    <div class="side-link">🧑‍🔧 Service Providers</div>
    <div class="side-link">📂 Categories</div>
    <div class="side-link">📋 Bookings</div>
    <div class="side-link">💳 Payments</div>
    <div class="side-link">🛡️ Safety Incidents</div>
  </div>
  <div class="admin-main">
    <div class="admin-topbar">
      <div style="font-size:13px; font-weight:bold; color:#1e293b;">Administrative Data Management Screen</div>
      <button style="background:#00A896; color:#fff; border:none; padding:5px 12px; border-radius:5px; font-size:11px; font-weight:bold;">+ Add Record</button>
    </div>
    <div class="admin-content">
      <div style="display:grid; grid-template-columns: repeat(4, 1fr); gap:10px;">
        <div style="background:#fff; border:1px solid #cbd5e1; border-radius:6px; padding:10px; border-top:3px solid #0047AB;">
          <div style="font-size:12px; font-weight:bold;">👤 Customers</div>
          <div style="font-size:9.5px; color:#64748b; margin:4px 0;">Manage registered clients &amp; accounts.</div>
          <button style="background:#f1f5f9; border:1px solid #cbd5e1; padding:3px 8px; border-radius:4px; font-size:9.5px;">Add Customer Ready</button>
        </div>

        <div style="background:#fff; border:1px solid #cbd5e1; border-radius:6px; padding:10px; border-top:3px solid #059669;">
          <div style="font-size:12px; font-weight:bold;">🧑‍🔧 Service Providers</div>
          <div style="font-size:9.5px; color:#64748b; margin:4px 0;">Verify certified technicians &amp; stats.</div>
          <button style="background:#f1f5f9; border:1px solid #cbd5e1; padding:3px 8px; border-radius:4px; font-size:9.5px;">Add Provider Ready</button>
        </div>

        <div style="background:#fff; border:1px solid #cbd5e1; border-radius:6px; padding:10px; border-top:3px solid #0047AB;">
          <div style="font-size:12px; font-weight:bold;">📂 Categories</div>
          <div style="font-size:9.5px; color:#64748b; margin:4px 0;">Dynamic Firestore trade catalogs.</div>
          <button style="background:#f1f5f9; border:1px solid #cbd5e1; padding:3px 8px; border-radius:4px; font-size:9.5px;">Manage &amp; Add Ready</button>
        </div>

        <div style="background:#fff; border:1px solid #cbd5e1; border-radius:6px; padding:10px; border-top:3px solid #EA580C;">
          <div style="font-size:12px; font-weight:bold;">🛠 Services</div>
          <div style="font-size:9.5px; color:#64748b; margin:4px 0;">Offered services &amp; base price ranges.</div>
          <button style="background:#f1f5f9; border:1px solid #cbd5e1; padding:3px 8px; border-radius:4px; font-size:9.5px;">Configure Rates</button>
        </div>

        <div style="background:#fff; border:1px solid #cbd5e1; border-radius:6px; padding:10px; border-top:3px solid #2563EB;">
          <div style="font-size:12px; font-weight:bold;">📋 Bookings</div>
          <div style="font-size:9.5px; color:#64748b; margin:4px 0;">Track live gig requests &amp; allocations.</div>
          <button style="background:#f1f5f9; border:1px solid #cbd5e1; padding:3px 8px; border-radius:4px; font-size:9.5px;">View Allocations</button>
        </div>

        <div style="background:#fff; border:1px solid #cbd5e1; border-radius:6px; padding:10px; border-top:3px solid #0D9488;">
          <div style="font-size:12px; font-weight:bold;">💳 Payments</div>
          <div style="font-size:9.5px; color:#64748b; margin:4px 0;">Platform transactions, commissions &amp; payouts.</div>
          <button style="background:#f1f5f9; border:1px solid #cbd5e1; padding:3px 8px; border-radius:4px; font-size:9.5px;">Audit Payouts</button>
        </div>

        <div style="background:#fff; border:1px solid #cbd5e1; border-radius:6px; padding:10px; border-top:3px solid #E11D48;">
          <div style="font-size:12px; font-weight:bold;">⭐ Reviews</div>
          <div style="font-size:9.5px; color:#64748b; margin:4px 0;">Customer ratings &amp; moderation.</div>
          <button style="background:#f1f5f9; border:1px solid #cbd5e1; padding:3px 8px; border-radius:4px; font-size:9.5px;">Moderate</button>
        </div>

        <div style="background:#fff; border:1px solid #cbd5e1; border-radius:6px; padding:10px; border-top:3px solid #4F46E5;">
          <div style="font-size:12px; font-weight:bold;">🔔 Notifications</div>
          <div style="font-size:9.5px; color:#64748b; margin:4px 0;">System broadcast &amp; push messaging.</div>
          <button style="background:#f1f5f9; border:1px solid #cbd5e1; padding:3px 8px; border-radius:4px; font-size:9.5px;">Push Alerts</button>
        </div>
      </div>
    </div>
  </div>
</div>
</body></html>"""
render_screen(admin_data_html, os.path.join(SCREENS_DIR, "screen_admin_data.png"), width=880, height=520)

# -------------------------------------------------------------
# 15. Karigar Dashboard & Job Requests Screen
# -------------------------------------------------------------
karigar_html = f"""<!DOCTYPE html><html><head><meta charset="utf-8"><style>{MOBILE_CSS}</style></head>
<body>
<div class="phone-frame">
  <div class="status-bar"><span>9:41</span><span>📶 🔋</span></div>
  <div class="app-bar" style="background:#0f172a;">
    <div class="app-title">🧑‍🔧 Karigar Console</div>
    <div style="font-size:11px; color:#22c55e;">● Online</div>
  </div>
  <div class="screen-content">
    <div style="background:#fff; border-radius:8px; padding:10px; border:1px solid #e2e8f0; margin-bottom:8px; display:flex; justify-content:space-between; align-items:center;">
      <div>
        <div style="font-size:12px; font-weight:bold;">Today's Earnings: ₹1,850</div>
        <div style="font-size:9.5px; color:#64748b;">4 Completed Services • 4.9 ★ Rating</div>
      </div>
      <span style="background:#dcfce7; color:#15803d; font-size:9.5px; padding:3px 8px; border-radius:10px; font-weight:bold;">Payout Ready</span>
    </div>

    <!-- New Job Alert Card -->
    <div style="background:#fff; border:2px solid #00A896; border-radius:10px; padding:10px; box-shadow:0 4px 10px rgba(0,0,0,0.06);">
      <div style="display:flex; justify-content:space-between; align-items:center;">
        <span style="background:#ffedd5; color:#c2410c; font-size:9px; padding:2px 6px; border-radius:4px; font-weight:bold;">🚨 NEW JOB REQUEST</span>
        <span style="font-size:11px; font-weight:bold; color:#00A896;">₹450 Est.</span>
      </div>
      <div style="font-size:12px; font-weight:bold; color:#1e293b; margin-top:4px;">Kitchen Sink Pipe Leakage Repair</div>
      <div style="font-size:10px; color:#475569; margin:2px 0;">Client: Henil Mungapara</div>
      <div style="font-size:9.5px; color:#64748b;">📍 Sunrise Heights, Gondal (1.8 km away)</div>
      <div style="display:flex; gap:8px; margin-top:10px;">
        <button style="flex:1; background:#ef4444; color:#fff; border:none; padding:8px; border-radius:6px; font-weight:bold; font-size:11px;">Decline</button>
        <button style="flex:2; background:#00A896; color:#fff; border:none; padding:8px; border-radius:6px; font-weight:bold; font-size:11px;">Accept Job (38s)</button>
      </div>
    </div>
  </div>
</div>
</body></html>"""
render_screen(karigar_html, os.path.join(SCREENS_DIR, "screen_karigar.png"), width=440, height=540)

print("All UI screen mockups generated successfully!")
