<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="village_dashboard.aspx.cs" Inherits="Society2024.village_dashboard" MasterPageFile="~/Site.Master"%>
<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css" />
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            font-family: 'Inter', sans-serif;
            min-height: 100vh;
            padding: 0;
            margin: 0;
        }

        .top-navbar {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
            padding: 0;
        }

        .navbar-content {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 18px 0;
        }

        .logo-section {
            display: flex;
            align-items: center;
            gap: 15px;
        }

        .logo-icon {
            width: 50px;
            height: 50px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 24px;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
        }

        .logo-text h4 {
            margin: 0;
            font-size: 20px;
            font-weight: 700;
            color: #1a202c;
        }

        .logo-text p {
            margin: 0;
            font-size: 12px;
            color: #718096;
            font-weight: 500;
        }

        .user-section {
            display: flex;
            align-items: center;
            gap: 15px;
        }

        .notification-bell {
            position: relative;
            width: 42px;
            height: 42px;
            background: #f7fafc;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.3s;
        }

        .notification-bell:hover {
            background: #edf2f7;
            transform: translateY(-2px);
        }

        .notification-badge {
            position: absolute;
            top: 8px;
            right: 8px;
            width: 8px;
            height: 8px;
            background: #f56565;
            border-radius: 50%;
            border: 2px solid white;
        }

        .user-profile {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 8px 15px;
            background: #f7fafc;
            border-radius: 10px;
            cursor: pointer;
            transition: all 0.3s;
        }

        .user-profile:hover {
            background: #edf2f7;
        }

        .user-avatar {
            width: 35px;
            height: 35px;
            border-radius: 8px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 600;
            font-size: 14px;
        }

        .user-info p {
            margin: 0;
            font-size: 13px;
            font-weight: 600;
            color: #2d3748;
        }

        .user-info small {
            font-size: 11px;
            color: #718096;
        }

        .main-content {
            padding: 30px 0;
        }

        .welcome-section {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 30px;
            margin-bottom: 30px;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
        }

        .welcome-section h2 {
            font-size: 28px;
            font-weight: 700;
            color: #1a202c;
            margin-bottom: 8px;
        }

        .welcome-section p {
            color: #718096;
            margin: 0;
            font-size: 15px;
        }

        .date-time {
            display: flex;
            align-items: center;
            gap: 20px;
            margin-top: 15px;
        }

        .date-badge, .time-badge {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 8px 16px;
            background: #f7fafc;
            border-radius: 10px;
            font-size: 13px;
            color: #4a5568;
            font-weight: 500;
        }

        .stat-card-modern {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            border-radius: 18px;
            padding: 25px;
            margin-bottom: 25px;
            box-shadow: 0 8px 30px rgba(0, 0, 0, 0.08);
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            position: relative;
            overflow: hidden;
        }

        .stat-card-modern::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 4px;
            background: linear-gradient(90deg, var(--card-gradient-start), var(--card-gradient-end));
        }

        .stat-card-modern:hover {
            transform: translateY(-8px);
            box-shadow: 0 15px 50px rgba(0, 0, 0, 0.15);
        }

        .stat-card-modern.water {
            --card-gradient-start: #4299e1;
            --card-gradient-end: #3182ce;
        }

        .stat-card-modern.home {
            --card-gradient-start: #48bb78;
            --card-gradient-end: #38a169;
        }

        .stat-card-modern.waste {
            --card-gradient-start: #ed8936;
            --card-gradient-end: #dd6b20;
        }

        .stat-card-modern.population {
            --card-gradient-start: #9f7aea;
            --card-gradient-end: #805ad5;
        }

        .card-header-modern {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 20px;
        }

        .card-icon-modern {
            width: 55px;
            height: 55px;
            border-radius: 14px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 26px;
            background: var(--icon-bg);
            color: var(--icon-color);
        }

        .stat-card-modern.water .card-icon-modern {
            --icon-bg: rgba(66, 153, 225, 0.1);
            --icon-color: #3182ce;
        }

        .stat-card-modern.home .card-icon-modern {
            --icon-bg: rgba(72, 187, 120, 0.1);
            --icon-color: #38a169;
        }

        .stat-card-modern.waste .card-icon-modern {
            --icon-bg: rgba(237, 137, 54, 0.1);
            --icon-color: #dd6b20;
        }

        .stat-card-modern.population .card-icon-modern {
            --icon-bg: rgba(159, 122, 234, 0.1);
            --icon-color: #805ad5;
        }

        .card-trend {
            display: flex;
            align-items: center;
            gap: 5px;
            padding: 6px 12px;
            background: rgba(72, 187, 120, 0.1);
            border-radius: 8px;
            font-size: 12px;
            font-weight: 600;
            color: #38a169;
        }

        .card-trend.down {
            background: rgba(245, 101, 101, 0.1);
            color: #e53e3e;
        }

        .card-title-modern {
            font-size: 13px;
            font-weight: 600;
            color: #718096;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 12px;
        }

        .card-value-modern {
            font-size: 32px;
            font-weight: 700;
            color: #1a202c;
            margin-bottom: 15px;
            display: flex;
            align-items: baseline;
            gap: 8px;
        }

        .card-value-modern .total {
            font-size: 20px;
            color: #a0aec0;
            font-weight: 600;
        }

        .progress-section {
            margin-top: 15px;
        }

        .progress-info {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 8px;
        }

        .progress-label {
            font-size: 13px;
            color: #4a5568;
            font-weight: 500;
        }

        .progress-percentage {
            font-size: 14px;
            font-weight: 700;
            color: var(--card-gradient-end);
        }

        .progress-modern {
            height: 8px;
            background: #f7fafc;
            border-radius: 10px;
            overflow: hidden;
        }

        .progress-bar-modern {
            height: 100%;
            border-radius: 10px;
            background: linear-gradient(90deg, var(--card-gradient-start), var(--card-gradient-end));
            transition: width 1s ease;
        }

        .card-footer-modern {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-top: 15px;
            padding-top: 15px;
            border-top: 1px solid #f1f3f5;
        }

        .footer-stat {
            display: flex;
            align-items: center;
            gap: 6px;
            font-size: 12px;
            color: #718096;
        }

        .footer-stat i {
            font-size: 14px;
        }

        .section-modern {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            border-radius: 18px;
            padding: 25px;
            box-shadow: 0 8px 30px rgba(0, 0, 0, 0.08);
            margin-bottom: 25px;
        }

        .section-header-modern {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 25px;
            padding-bottom: 15px;
            border-bottom: 2px solid #f1f3f5;
        }

        .section-title-modern {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .section-title-modern h5 {
            margin: 0;
            font-size: 18px;
            font-weight: 700;
            color: #1a202c;
        }

        .section-icon {
            width: 38px;
            height: 38px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 16px;
        }

        .view-all-link {
            color: #667eea;
            font-size: 13px;
            font-weight: 600;
            text-decoration: none;
            display: flex;
            align-items: center;
            gap: 5px;
            transition: all 0.3s;
        }

        .view-all-link:hover {
            color: #764ba2;
            gap: 8px;
        }

        .activity-item-modern {
            display: flex;
            gap: 15px;
            padding: 18px;
            background: #f7fafc;
            border-radius: 12px;
            margin-bottom: 12px;
            transition: all 0.3s;
        }

        .activity-item-modern:hover {
            background: #edf2f7;
            transform: translateX(5px);
        }

        .activity-item-modern:last-child {
            margin-bottom: 0;
        }

        .activity-icon-modern {
            width: 48px;
            height: 48px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
            flex-shrink: 0;
        }

        .activity-icon-modern.payment {
            background: rgba(72, 187, 120, 0.15);
            color: #38a169;
        }

        .activity-icon-modern.announcement {
            background: rgba(237, 137, 54, 0.15);
            color: #dd6b20;
        }

        .activity-icon-modern.scheme {
            background: rgba(66, 153, 225, 0.15);
            color: #3182ce;
        }

        .activity-content {
            flex: 1;
        }

        .activity-title {
            font-size: 15px;
            font-weight: 600;
            color: #1a202c;
            margin-bottom: 4px;
        }

        .activity-description {
            font-size: 13px;
            color: #718096;
            margin-bottom: 8px;
        }

        .activity-meta {
            display: flex;
            align-items: center;
            gap: 15px;
        }

        .activity-time {
            display: flex;
            align-items: center;
            gap: 5px;
            font-size: 12px;
            color: #a0aec0;
        }

        .activity-badge {
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 600;
        }

        .activity-badge.success {
            background: rgba(72, 187, 120, 0.15);
            color: #38a169;
        }

        .activity-badge.warning {
            background: rgba(237, 137, 54, 0.15);
            color: #dd6b20;
        }

        .activity-badge.info {
            background: rgba(66, 153, 225, 0.15);
            color: #3182ce;
        }

        .quick-action-modern {
            background: rgba(255, 255, 255, 0.8);
            border: 2px solid transparent;
            border-radius: 14px;
            padding: 20px;
            text-align: center;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            cursor: pointer;
            margin-bottom: 15px;
            display: block;
            text-decoration: none;
        }

        .quick-action-modern:hover {
            background: white;
            border-color: #667eea;
            transform: translateY(-5px);
            box-shadow: 0 10px 30px rgba(102, 126, 234, 0.2);
        }

        .action-icon-modern {
            width: 60px;
            height: 60px;
            margin: 0 auto 12px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 14px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 26px;
            transition: all 0.3s;
        }

        .quick-action-modern:hover .action-icon-modern {
            transform: scale(1.1) rotate(5deg);
        }

        .action-title {
            font-size: 14px;
            font-weight: 600;
            color: #2d3748;
            margin: 0;
        }

        .population-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 15px;
            margin-top: 28px;
        }

        .population-item {
            background: #f7fafc;
            padding: 15px;
            border-radius: 10px;
            text-align: center;
        }

        .population-item i {
            font-size: 24px;
            margin-bottom: 8px;
        }

        .population-item.male i {
            color: #3182ce;
        }

        .population-item.female i {
            color: #d53f8c;
        }

        .population-value {
            font-size: 22px;
            font-weight: 700;
            color: #1a202c;
            display: block;
        }

        .population-label {
            font-size: 12px;
            color: #718096;
            font-weight: 500;
        }

        @media (max-width: 768px) {
            .logo-text h4 {
                font-size: 16px;
            }
            .logo-text p {
                font-size: 10px;
            }
            .user-info {
                display: none;
            }
            .welcome-section h2 {
                font-size: 22px;
            }
            .date-time {
                flex-direction: column;
                gap: 10px;
            }
        }
    </style>


        <!-- Main Content -->
        <div class="container main-content">


            <!-- Statistics Cards -->
            <div class="row">

                                <!-- Home Tax -->
                <div class="col-lg-3 col-md-6">
                    <div class="stat-card-modern home">
                        <div class="card-header-modern">
                            <div class="card-icon-modern">
                                <i class="fas fa-home"></i>
                            </div>
                            <div class="card-trend">
                                <i class="fas fa-arrow-up"></i>
                                <span>8%</span>
                            </div>
                        </div>
                        <div class="card-title-modern">Property Tax (Yearly)</div>
                        <div class="card-value-modern">
                            <span><asp:Label ID="lblHomeTaxPaid" runat="server"></asp:Label></span>
                            <span class="total">/ <asp:Label ID="lblHomeTaxTotal" runat="server"></asp:Label></span>
                        </div>
                        <div class="progress-section">
                            <div class="progress-info">
                                <span class="progress-label">Collection Rate</span>
                                <span class="progress-percentage"><%= HomeTaxPercentage %>%</span>
                            </div>
                            <div class="progress-modern">
                                <div class="progress-bar-modern" style="width: <%= HomeTaxPercentage %>%"></div>
                            </div>
                        </div>
                        <div class="card-footer-modern">
                            <div class="footer-stat">
                                <i class="fas fa-users"></i>
                                <span>356 Paid</span>
                            </div>
                            <div class="footer-stat">
                                <i class="fas fa-clock"></i>
                                <span>94 Pending</span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Water Tax -->
                <div class="col-lg-3 col-md-6">
                    <div class="stat-card-modern water">
                        <div class="card-header-modern">
                            <div class="card-icon-modern">
                                <i class="fas fa-tint"></i>
                            </div>
                            <div class="card-trend">
                                <i class="fas fa-arrow-up"></i>
                                <span>12%</span>
                            </div>
                        </div>
                        <div class="card-title-modern">Water Tax (Monthly)</div>
                        <div class="card-value-modern">
                            <span><asp:Label ID="lblWaterTaxPaid" runat="server"></asp:Label></span>
                            <span class="total">/ <asp:Label ID="lblWaterTaxTotal" runat="server"></asp:Label></span>
                        </div>
                        <div class="progress-section">
                            <div class="progress-info">
                                <span class="progress-label">Collection Rate</span>
                                <span class="progress-percentage"><%= WaterTaxPercentage %>%</span>
                            </div>
                            <div class="progress-modern">
                                <div class="progress-bar-modern" style="width: <%= WaterTaxPercentage %>%"></div>
                            </div>
                        </div>
                        <div class="card-footer-modern">
                            <div class="footer-stat">
                                <i class="fas fa-users"></i>
                                <span>142 Paid</span>
                            </div>
                            <div class="footer-stat">
                                <i class="fas fa-clock"></i>
                                <span>58 Pending</span>
                            </div>
                        </div>
                    </div>
                </div>



                <!-- Waste Tax -->
                <div class="col-lg-3 col-md-6">
                    <div class="stat-card-modern waste">
                        <div class="card-header-modern">
                            <div class="card-icon-modern">
                                <i class="fas fa-recycle"></i>
                            </div>
                            <div class="card-trend">
                                <i class="fas fa-arrow-up"></i>
                                <span>15%</span>
                            </div>
                        </div>
                        <div class="card-title-modern">Waste Tax (Monthly)</div>
                        <div class="card-value-modern">
                            <span><asp:Label ID="lblWasteTaxPaid" runat="server"></asp:Label></span>
                            <span class="total">/ <asp:Label ID="lblWasteTaxTotal" runat="server"></asp:Label></span>
                        </div>
                        <div class="progress-section">
                            <div class="progress-info">
                                <span class="progress-label">Collection Rate</span>
                                <span class="progress-percentage"><%= WasteTaxPercentage %>%</span>
                            </div>
                            <div class="progress-modern">
                                <div class="progress-bar-modern" style="width: <%= WasteTaxPercentage %>%"></div>
                            </div>
                        </div>
                        <div class="card-footer-modern">
                            <div class="footer-stat">
                                <i class="fas fa-users"></i>
                                <span>178 Paid</span>
                            </div>
                            <div class="footer-stat">
                                <i class="fas fa-clock"></i>
                                <span>22 Pending</span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Population -->
                <div class="col-lg-3 col-md-6">
                    <div class="stat-card-modern population">
                        <div class="card-header-modern">
                            <div class="card-icon-modern">
                                <i class="fas fa-users"></i>
                            </div>
                            <div class="card-trend">
                                <i class="fas fa-arrow-up"></i>
                                <span>2%</span>
                            </div>
                        </div>
                        <div class="card-title-modern">Total Population</div>
                        <div class="card-value-modern">
                            <span><asp:Label ID="lblTotalPopulation" runat="server"></asp:Label></span>
                        </div>
                        <div class="population-grid">
                            <div class="population-item male">
                                <i class="fas fa-male"></i>
                                <span class="population-value"><asp:Label ID="lblMalePopulation" runat="server"></asp:Label></span>
                                <span class="population-label">Male</span>
                            </div>
                            <div class="population-item female">
                                <i class="fas fa-female"></i>
                                <span class="population-value"><asp:Label ID="lblFemalePopulation" runat="server"></asp:Label></span>
                                <span class="population-label">Female</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Recent Activities & Quick Actions -->
            <div class="row">
                <!-- Recent Activities -->
                <div class="col-lg-8">
                    <div class="section-modern">
                        <div class="section-header-modern">
                            <div class="section-title-modern">
                                <div class="section-icon">
                                    <i class="fas fa-history"></i>
                                </div>
                                <h5>Recent Activities</h5>
                            </div>
                            <a href="#" class="view-all-link">
                                View All
                                <i class="fas fa-arrow-right"></i>
                            </a>
                        </div>

                        <asp:Repeater ID="rptRecentActivities" runat="server">
                            <ItemTemplate>
                                <div class="activity-item-modern">
                                    <div class="activity-icon-modern <%# Eval("IconClass") %>">
                                        <i class="fas <%# Eval("Icon") %>"></i>
                                    </div>
                                    <div class="activity-content">
                                        <div class="activity-title"><%# Eval("Title") %></div>
                                        <div class="activity-description"><%# Eval("Description") %></div>
                                        <div class="activity-meta">
                                            <div class="activity-time">
                                                <i class="far fa-clock"></i>
                                                <span><%# Eval("Time") %></span>
                                            </div>
                                            <div class="activity-badge <%# Eval("BadgeClass") %>">
                                                <%# Eval("Status") %>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </ItemTemplate>
                        </asp:Repeater>
                    </div>
                </div>

                <!-- Quick Actions -->
                <div class="col-lg-4">
                    <div class="section-modern">
                        <div class="section-header-modern">
                            <div class="section-title-modern">
                                <div class="section-icon">
                                    <i class="fas fa-bolt"></i>
                                </div>
                                <h5>Quick Actions</h5>
                            </div>
                        </div>

                        <asp:LinkButton ID="btnAddAnnouncement" runat="server" CssClass="quick-action-modern" OnClick="btnAddAnnouncement_Click">
                            <div class="action-icon-modern">
                                <i class="fas fa-bullhorn"></i>
                            </div>
                            <p class="action-title">Add Announcement</p>
                        </asp:LinkButton>

                        <asp:LinkButton ID="btnGenerateTaxes" runat="server" CssClass="quick-action-modern" OnClick="btnGenerateTaxes_Click">
                            <div class="action-icon-modern">
                                <i class="fas fa-file-invoice-dollar"></i>
                            </div>
                            <p class="action-title">Taxes</p>
                        </asp:LinkButton>

                        <asp:LinkButton ID="btnAddScheme" runat="server" CssClass="quick-action-modern" OnClick="btnAddScheme_Click">
                            <div class="action-icon-modern">
                                <i class="fas fa-clipboard-list"></i>
                            </div>
                            <p class="action-title">Add Government Scheme</p>
                        </asp:LinkButton>

                        <asp:LinkButton ID="btnViewReports" runat="server" CssClass="quick-action-modern" OnClick="btnViewReports_Click">
                            <div class="action-icon-modern">
                                <i class="fas fa-chart-line"></i>
                            </div>
                            <p class="action-title">Analytics & Reports</p>
                        </asp:LinkButton>
                    </div>
                </div>
            </div>
        </div>

     <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.1/dist/umd/popper.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>
    <script>
        // Animate progress bars on load
        window.addEventListener('load', function() {
            document.querySelectorAll('.progress-bar-modern').forEach(function(bar) {
                bar.style.transition = 'width 1.5s ease-out';
            });
        });

        // Update time every second
        setInterval(function() {
            var now = new Date();
            var timeString = now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
            var timeElement = document.querySelector('.time-badge span');
            if (timeElement) {
                timeElement.textContent = timeString;
            }
        }, 1000);
    </script>
    </asp:Content>