<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="t_n_c.aspx.cs" Inherits="Society2024.t_n_c" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Society Hub - Terms and Conditions</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #f0f8ff 0%, #e6f3ff 100%);
            min-height: 100vh;
            color: #2c3e50;
            line-height: 1.6;
        }

        header {
            background: rgba(248, 250, 252, 0.95);
            backdrop-filter: blur(10px);
            position: fixed;
            top: 0;
            width: 100%;
            z-index: 1000;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
            transition: all 0.3s ease;
            border-bottom: 1px solid #e2e8f0;
        }

        nav {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 1rem 0;
        }

        .logo {
            font-size: 2.5rem;
            font-weight: 700;
            color: #4287f5;
            margin-bottom: 10px;
            letter-spacing: -0.5px;
        }

        .nav-links {
            display: flex;
            list-style: none;
            gap: 2rem;
            align-items: center;
        }

            .nav-links a {
                text-decoration: none;
                color: #64748b;
                font-weight: 500;
                font-size: 0.9rem;
                transition: color 0.3s ease;
            }

                .nav-links a:hover {
                    color: #2d3748;
                }


        .cta-button {
            background: #3b82f6;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 6px;
            font-weight: 600;
            font-size: 0.9rem;
            text-decoration: none;
            transition: all 0.3s ease;
            box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
        }

            .cta-button:hover {
                background: #2563eb;
                transform: translateY(-1px);
                box-shadow: 0 4px 12px rgba(59, 130, 246, 0.15);
            }


        .containerNav {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 20px;
        }


        .container {
            max-width: 900px;
            margin: 0 auto;
            padding: 40px 20px;
        }

        .header {
            text-align: center;
            margin: 50px 0;
            padding: 30px;
            background: white;
            border-radius: 20px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.05);
            border: 1px solid rgba(66, 135, 245, 0.1);
        }

        .logo {
            font-size: 2.5rem;
            font-weight: 700;
            color: #4287f5;
            margin-bottom: 10px;
            letter-spacing: -0.5px;
        }

        .subtitle {
            font-size: 1.2rem;
            color: #6b7280;
            font-weight: 500;
        }

        .company-info {
            background: linear-gradient(135deg, #4287f5 0%, #5b9cf6 100%);
            color: white;
            padding: 25px;
            border-radius: 15px;
            margin-bottom: 30px;
            box-shadow: 0 8px 25px rgba(66, 135, 245, 0.2);
        }

            .company-info h2 {
                font-size: 1.4rem;
                margin-bottom: 15px;
                font-weight: 600;
            }

        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
        }

        .info-item {
            background: rgba(255, 255, 255, 0.15);
            padding: 12px 16px;
            border-radius: 8px;
            backdrop-filter: blur(10px);
        }

        .info-label {
            font-size: 0.85rem;
            opacity: 0.9;
            margin-bottom: 4px;
        }

        .info-value {
            font-weight: 600;
            font-size: 1rem;
        }

        .content {
            background: white;
            border-radius: 15px;
            padding: 40px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.05);
            border: 1px solid rgba(66, 135, 245, 0.1);
        }

        .section {
            margin-bottom: 35px;
            padding-bottom: 25px;
            border-bottom: 1px solid #f1f5f9;
        }

            .section:last-child {
                border-bottom: none;
                margin-bottom: 0;
            }

        .section-title {
            font-size: 1.3rem;
            font-weight: 700;
            color: #4287f5;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .section-number {
            background: #4287f5;
            color: white;
            width: 28px;
            height: 28px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 0.9rem;
            font-weight: 600;
        }

        .section-content {
            color: #374151;
            font-size: 1rem;
            line-height: 1.7;
        }

            .section-content p {
                margin-bottom: 15px;
            }

        .highlight-box {
            background: #f8faff;
            border: 2px solid #e5f0ff;
            border-radius: 10px;
            padding: 20px;
            margin: 20px 0;
        }

            .highlight-box h4 {
                color: #4287f5;
                font-weight: 600;
                margin-bottom: 10px;
            }

        .bullet-list {
            list-style: none;
            padding-left: 0;
        }

            .bullet-list li {
                position: relative;
                padding-left: 25px;
                margin-bottom: 12px;
                color: #374151;
            }

                .bullet-list li::before {
                    content: "•";
                    color: #4287f5;
                    font-weight: bold;
                    position: absolute;
                    left: 0;
                    font-size: 1.2rem;
                }

        .contact-info {
            background: linear-gradient(135deg, #10b981 0%, #34d399 100%);
            color: white;
            padding: 25px;
            border-radius: 12px;
            margin-top: 30px;
        }

            .contact-info h3 {
                margin-bottom: 15px;
                font-weight: 600;
            }

        .contact-item {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 8px;
        }

            .contact-item:last-child {
                margin-bottom: 0;
            }

        .emphasis {
            font-weight: 600;
            color: #4287f5;
        }

        @media (max-width: 768px) {
            .container {
                padding: 20px 15px;
            }

            .header {
                padding: 20px;
                margin-bottom: 30px;
            }

            .logo {
                font-size: 2rem;
            }

            .content {
                padding: 25px 20px;
            }

            .section-title {
                font-size: 1.2rem;
            }

            .info-grid {
                grid-template-columns: 1fr;
            }
        }

        .fade-in {
            animation: fadeIn 0.8s ease-in-out;
        }

        @keyframes fadeIn {
            from {
                opacity: 0;
                transform: translateY(20px);
            }

            to {
                opacity: 1;
                transform: translateY(0);
            }
        }


        /* Mobile Navigation */
        @media (max-width: 768px) {
            .nav-links {
                position: fixed;
                top: 80px;
                right: -100%;
                width: 100%;
                height: calc(100vh - 80px);
                background: rgba(248, 250, 252, 0.98);
                backdrop-filter: blur(20px);
                flex-direction: column;
                justify-content: flex-start;
                align-items: center;
                padding: 2rem 0;
                transition: right 0.3s ease;
                border-left: 1px solid #e2e8f0;
                z-index: 999;
            }

                .nav-links.active {
                    right: 0;
                }

                .nav-links li {
                    margin: 1rem 0;
                }

                .nav-links a {
                    font-size: 1.1rem;
                    padding: 1rem 2rem;
                    display: block;
                    text-align: center;
                }

            .mobile-menu-toggle.active span:nth-child(1) {
                transform: rotate(-45deg) translate(-5px, 6px);
            }

            .mobile-menu-toggle.active span:nth-child(2) {
                opacity: 0;
            }

            .mobile-menu-toggle.active span:nth-child(3) {
                transform: rotate(45deg) translate(-5px, -6px);
            }

            .mobile-menu-toggle {
                display: flex;
            }
        }


        /* Mobile Menu Toggle */
        .mobile-menu-toggle {
            display: none;
            flex-direction: column;
            cursor: pointer;
            padding: 8px;
        }

            .mobile-menu-toggle span {
                width: 25px;
                height: 3px;
                background: #64748b;
                margin: 3px 0;
                transition: 0.3s;
            }

        /* Print styles */
        @media print {

            .cta-section {
                break-inside: avoid;
            }

            .nav-links, .mobile-menu-toggle, .hero-buttons {
                display: none;
            }
        }

        @media (max-width: 768px) {
    .mobile-menu-toggle {
        display: flex;
        z-index: 2100; /* higher than nav-links */
    }
}
    </style>
</head>
<body>
    <header>
        <nav class="containerNav">
            <div class="logo">CHSHub</div>
            <ul class="nav-links">
                <li><a href="landing_page.aspx">Features</a></li>
                <li><a href="landing_page.aspx">Mobile App</a></li>
                <li><a href="landing_page.aspx">Contact</a></li>
                <li><a href="login1.aspx" style="color: white" class="cta-button">Login</a></li>
            </ul>
            <div class="mobile-menu-toggle">
                <span></span>
                <span></span>
                <span></span>
            </div>
        </nav>
    </header>
    <div class="container">
        <div class="header fade-in">
            <div class="subtitle">Terms and Conditions</div>
        </div>

        <div class="company-info fade-in">
            <h2>Application Information</h2>
            <div class="info-grid">
                <div class="info-item">
                    <div class="info-label">Company Name</div>
                    <div class="info-value">Vengurla Tech</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Application Name</div>
                    <div class="info-value">Society Hub</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Governing Law</div>
                    <div class="info-value">Laws of India</div>
                </div>
            </div>
        </div>

        <div class="content fade-in">
            <div class="section">
                <h3 class="section-title">
                    <span class="section-number">1</span>
                    Services
                </h3>
                <div class="section-content">
                    <p>Society Hub provides comprehensive services including payments, facility booking, visitor management, announcements, polls, and chat functionality.</p>
                    <p>Different roles are available in the app: <span class="emphasis">residents</span>, <span class="emphasis">admins</span>, and <span class="emphasis">guards</span>.</p>
                </div>
            </div>

            <div class="section">
                <h3 class="section-title">
                    <span class="section-number">2</span>
                    User Accounts
                </h3>
                <div class="section-content">
                    <div class="highlight-box">
                        <h4>Registration</h4>
                        <p>Admins register with phone/email and OTP. Admins add all flat owners to the system.</p>
                    </div>
                    <div class="highlight-box">
                        <h4>Login</h4>
                        <p>Admins log in with username and password. Residents log in with phone and OTP.</p>
                    </div>
                    <div class="highlight-box">
                        <h4>Information Required</h4>
                        <ul class="bullet-list">
                            <li>Name and contact information</li>
                            <li>Phone number and email address</li>
                            <li>Residential address and flat number</li>
                            <li>Valid ID proof documentation</li>
                        </ul>
                    </div>
                    <p><span class="emphasis">Responsibility:</span> Users are responsible for keeping login details safe. Misuse due to negligence will not be the company's responsibility.</p>
                </div>
            </div>

            <div class="section">
                <h3 class="section-title">
                    <span class="section-number">3</span>
                    Payments
                </h3>
                <div class="section-content">
                    <ul class="bullet-list">
                        <li>Subscription fees may apply to societies or residents</li>
                        <li>Payments may be recurring (monthly or yearly) or one-time, as decided by the society</li>
                        <li><span class="emphasis">Refunds are not provided unless required by law</span></li>
                    </ul>
                </div>
            </div>

            <div class="section">
                <h3 class="section-title">
                    <span class="section-number">4</span>
                    User Responsibilities
                </h3>
                <div class="section-content">
                    <p>Users must use the app legally, respect others, and avoid spam.</p>
                    <div class="highlight-box">
                        <h4>Prohibited Content Includes:</h4>
                        <ul class="bullet-list">
                            <li>Abusive language or harassment</li>
                            <li>Misinformation and false claims</li>
                            <li>Illegal files or content</li>
                        </ul>
                    </div>
                </div>
            </div>

            <div class="section">
                <h3 class="section-title">
                    <span class="section-number">5</span>
                    Data & Privacy
                </h3>
                <div class="section-content">
                    <div class="highlight-box">
                        <h4>Data Collected</h4>
                        <p>Name, phone number, email, address, ID proofs, and payment details.</p>
                    </div>
                    <div class="highlight-box">
                        <h4>Third Parties</h4>
                        <p>Data may be shared with service providers such as payment gateways and notification services.</p>
                    </div>
                    <div class="highlight-box">
                        <h4>Data Retention</h4>
                        <p>User data is deleted within <span class="emphasis">30 days</span> after account deletion.</p>
                    </div>
                    <p><span class="emphasis">Rights:</span> Users can request data deletion by contacting support.</p>
                </div>
            </div>

            <div class="section">
                <h3 class="section-title">
                    <span class="section-number">6</span>
                    Intellectual Property
                </h3>
                <div class="section-content">
                    <p>The software, design, and code remain with the company.</p>
                    <p>Residents may post content (e.g., photos, announcements). By posting, they give the company the right to display it in the app.</p>
                </div>
            </div>

            <div class="section">
                <h3 class="section-title">
                    <span class="section-number">7</span>
                    Modifications
                </h3>
                <div class="section-content">
                    <ul class="bullet-list">
                        <li>Features may be added or removed with or without notice</li>
                        <li>Terms and Conditions may change at any time</li>
                        <li>Users will be notified by email or in-app notification</li>
                    </ul>
                </div>
            </div>

            <div class="section">
                <h3 class="section-title">
                    <span class="section-number">8</span>
                    Termination
                </h3>
                <div class="section-content">
                    <p>Accounts may be suspended or terminated for misuse, violation of rules, or non-payment.</p>
                    <p>On termination, user data will be deleted from active systems within <span class="emphasis">30 days</span>.</p>
                </div>
            </div>

            <div class="section">
                <h3 class="section-title">
                    <span class="section-number">9</span>
                    Liability & Disclaimer
                </h3>
                <div class="section-content">
                    <p>The company is not responsible for downtime, incorrect information entered by residents, or disputes between users.</p>
                    <p>The service is provided <span class="emphasis">"as is"</span> without any guarantee of uninterrupted availability.</p>
                </div>
            </div>

            <div class="section">
                <h3 class="section-title">
                    <span class="section-number">10</span>
                    Support & Contact
                </h3>
                <div class="section-content">
                    <div class="contact-info">
                        <h3>Get in Touch</h3>
                        <div class="contact-item">
                            <span>📧</span>
                            <span><strong>Email:</strong> hr@vengurlatech.com</span>
                        </div>
                        <div class="contact-item">
                            <span>⏱️</span>
                            <span><strong>Response Time:</strong> Within 1 business day</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>

        // Mobile menu toggle functionality
        const mobileToggle = document.querySelector('.mobile-menu-toggle');
        const navLinks = document.querySelector('.nav-links');

        if (mobileToggle && navLinks) {
            mobileToggle.addEventListener('click', function () {
                navLinks.classList.toggle('active');
                this.classList.toggle('active');
            });
        }
        // Add smooth scroll animation to sections
        const observerOptions = {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        };

        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.style.opacity = '1';
                    entry.target.style.transform = 'translateY(0)';
                }
            });
        }, observerOptions);

        // Observe all sections
        document.querySelectorAll('.section').forEach(section => {
            section.style.opacity = '0';
            section.style.transform = 'translateY(30px)';
            section.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
            observer.observe(section);
        });
    </script>
</body>
</html>
