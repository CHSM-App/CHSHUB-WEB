<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="dashboard.aspx.cs" Inherits="Society.dashboard" MasterPageFile="~/Site.Master" %>

<%@ Register Assembly="System.Web.DataVisualization, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" Namespace="System.Web.UI.DataVisualization.Charting" TagPrefix="asp" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <link href="css/layout.css" rel="stylesheet" />
    <style>
        *{
             color:#012970; 
               font-weight:600;
                  font-family: "Open Sans", sans-serif;
        }
        .netlify-color {
/*            --start: #defffe;
            --first: #edf4ff;
            color: #0d0d3d;
            
            --end: #f6f9fd;
            background: radial-gradient(16rem 100% at 6.64% 0, var(--start) 0, var(--first) 42.5%, var(--end) 100%);*/
            background:white;
            border: 1px solid #1e1e4c26;
        }

        .top-dashboard {
            display: flex;
            gap: 20px;

            justify-content: center;
        }

        .top-card {
            flex: 1;
            /*        min-width: 250px;
        max-width: 300px;*/
            padding: 20px;
            box-shadow: rgba(99, 99, 99, 0.2) 0px 2px 8px 0px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            height: 100%;
            transition: all 0.3s ease; /* Smooth transition */
        }

            .top-card:hover {
                box-shadow: 0 0 10px #18008f40;
                transform: scale(1.01);
                z-index:1000;
                color:red;
            }

            .top-card h2 {
                font-size: 14px;
                font-weight: normal;
                margin: 0 0 10px;
            }

            .top-card .top-value {
                font-size: 28px;
                font-weight: bold;
            }

            .top-card .top-subtitle {
                font-size: 14px;
                margin-top: 4px;
                opacity: 0.9;
            }

            .top-card .top-icon {
                font-size: 24px;
                padding: 17px;
                border-radius: 12px;
                background-color: rgba(255, 255, 255, 0.147);
            }

        .helpdesk-card {
            background-color: #ecf0f1;
            padding: 30px 20px;
            border-radius: 10px;
            width: 45%;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }

            .helpdesk-card:hover {
                transform: translateY(-5px);
                box-shadow: 0 8px 16px rgba(0,0,0,0.15);
            }

        .helpdesk-card-title {
            font-size: 18px;
            color: #34495e;
            margin-bottom: 15px;
        }

        .helpdesk-card-number {
            font-size: 28px;
            font-weight: bold;
            color: #2c3e50;
        }

        .helpdesk-cards {
            display: flex;
            justify-content: space-around;
            gap: 20px;
        }

        .hov {
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }

            .hov:hover {
                transform: translateY(-2px);
                box-shadow: 0 8px 16px rgba(0,0,0,0.15);
            }

        .expense-heading {
            font-family: 'Microsoft Sans Serif', sans-serif;
            font-size: 18pt;
            color: black; /* Change if needed */
            text-align: Center;
            margin-left: 10px; /* Adjust spacing */
        }

        .income-heading {
            font-family: 'Microsoft Sans Serif', sans-serif;
            font-size: 18pt;
            color: black; /* Change if needed */
            text-align: Center;
            margin-left: 10px; /* Adjust spacing */
        }

        .dropdown-divider {
            margin: 6px -1px;
            height: 1px;
            background: radial-gradient(black, transparent);
            /* margin: var(--bs-dropdown-divider-margin-y) 0; */
            overflow: hidden;
            border-top: 1px solid var(--bs-dropdown-divider-bg);
            opacity: 1;
        }

        .box-table {
            border-radius: 16px;
            padding: 18px;
            box-shadowQ: rgba(0, 0, 0, 0.16) 0px 10px 36px 0px, rgba(0, 0, 0, 0.06) 0px 0px 0px 1px;
            margin-bottom: 38px;
            background: white;
        }

        .table-heading {
            text-decoration: underline;
        }

        .btn-custom {
            margin-top: 30px;
            width: 106%;
            padding: 12px;
            background: linear-gradient(to right, #466CD9, #5D8FEF);
            color: white;
            border: none;
            border-radius: 25px;
            font-size: 16px;
            cursor: pointer;
        }

        .custom-table {
            width: fit-content;
            background: white;
            border-collapse: collapse;
            font-family: 'Segoe UI', sans-serif;
            /*      box-shadow: rgba(50, 50, 93, 0.25) 0px 50px 100px -20px, rgba(0, 0, 0, 0.3) 0px 30px 60px -30px, rgba(10, 37, 64, 0.35) 0px -2px 6px 0px inset;*/ */
        }

            .custom-table th {
                padding: 7px 25px;
                border: hidden;
            }

            .custom-table td {
                padding: 12px 16px;
                border: hidden;
            }

        .link-style {
            color: black;
            text-decoration: none;
        }

            .link-style:hover {
                text-decoration: underline;
            }

        .update-card {
            overflow: auto;
            width: 100%;
            padding: 10px 13px;
            height: 225px;
            overflow-x: hidden;
        }

        .update-grid {
            margin-bottom: 5px;
            padding: 7px;
            width: 100%;
            border-radius: 16px;
            border: 2px solid #d6d6d6;
        }

        .inner-div {
            width: 100%;
            justify-content: space-between;
            display: flex;
        }

        .notify-div {
            width: 245px;
            height: 25px;
            word-wrap: break-word;
            overflow: hidden;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }


        .header-card {
            padding-top: 17px;
            padding-bottom: 5px;
            padding-left: 21px;
            font-weight: bold;
            color: navy;
        }

        .divider {
            height: 1px;
            /*            background: #0000004d;*/
            width: 88%;
            margin: 0 21px;
        }


        .pdc-card-container {
            max-width: 600px;
            width: 100%;
            padding: 0 16px;
        }

        .pdc-cheque-card {
            display: flex;
            align-items: center;
            justify-content: space-between;
            height: 60px;
            background-color: #fff;
            border-radius: 16px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.08);
            padding: 0 6px;
            /*            transition: box-shadow 0.3s ease;*/

            border: 1px solid #8080805c;
            margin-bottom: 7px;
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }

            .pdc-cheque-card:hover {
                /*                box-shadow: 0 6px 12px rgba(0, 0, 0, 0.1);
                transform:scale(1.01)*/

                transform: scale(1.03);
                box-shadow: 0 8px 20px rgba(0, 0, 0, 0.15);
                cursor: pointer;
            }

        .pdc-calendar-box {
            width: 48px;
            height: 48px;
            background-color: #dbeafe;
            color: #1d4ed8;
            border-radius: 8px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            margin-right: 16px;
            flex-shrink: 0;
        }

            .pdc-calendar-box span:first-child {
                font-size: 10px;
                font-weight: 600;
            }

            .pdc-calendar-box span:last-child {
                font-size: 18px;
                font-weight: 700;
                margin-top: -4px;
            }

        .pdc-details {
            flex-grow: 1;
            display: flex;
            flex-direction: column;
        }

            .pdc-details .pdc-name {
                font-size: 14px;
                font-weight: 500;
                color: #1f2937;
            }

            .pdc-details .pdc-cheque-number {
                font-size: 12px;
                color: #6b7280;
            }

        .pdc-amount {
            font-size: 14px;
            font-weight: 600;
            color: #2563eb;
            text-align: right;
            margin-left: 16px;
            white-space: nowrap;
        }

        .card-radius {
            border-radius: 15px;
        }

        .pdc-weekly {
            width: 50%;
            height: 100%;
            border-radius: 12px;
        }

        .custom-width {
            width: calc(95% / 3);
        }

        @media (max-width: 431px) {
            .top-dashboard {
                flex-direction: column;
            }

            .custom-width {
                width: 100%;
            }

            .netlify-color {
                background: white;
            }

            .layout-blue {
                flex-direction: column;
                background: none;
            }

            .pdc-weekly {
                width: 100%;
            }
        }

        @media(max-width:321px) {
            .custom-width {
                width: 91%;
            }

            .custom-width-container {
                width: 91%;
            }
        }

        .recent-container {
            max-width: 379px;
            margin: 2px auto;
            background: #fff;
            border-radius: 16px;
            padding: 0 9px;
            box-shadow: 0 8px 24px rgba(0,0,0,0.08);
        }

        .recent-heading {
            margin-bottom: 24px;
            font-size: 1.8rem;
            color: #1f2937;
            text-align: center;
        }

        .recent-activity {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 8px 0;
            border-bottom: 1px solid #e5e7eb;
        }

            .recent-activity:last-child {
                border-bottom: none;
            }

        .recent-activity-left {
            display: flex;
            align-items: center;
        }

        .recent-icon {
            width: 40px;
            height: 40px;
            background-color: #eef2ff;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin-right: 14px;
            font-size: 20px;
            color: #4f46e5;
        }

        canvas {
            max-width: 900px;
            margin: auto;
            display: block;
        }

        .recent-details {
            display: flex;
            flex-direction: column;
        }

            .recent-details .recent-text {
                font-weight: 600;
                color: #111827;
            }

            .recent-details .recent-time {
                font-size: 12px;
                /*      color: #6b7280;*/
                color: #9b9b9b;
            }

        .recent-activity-right {
            font-weight: 600;
            font-size: 0.95rem;
        }

        .recent-amount {
            color: #16a34a;
        }

        .recent-apartment {
            color: #2563eb;
        }

        .recent-new-member {
            color: #9333ea;
        }

        .green-bg {
            --tw-bg-opacity: 1;
            background-color: rgb(34 197 94 / var(--tw-bg-opacity, 1));
        }

        .blue-bg {
            --tw-bg-opacity: 1;
            background-color: rgb(59 130 246 / var(--tw-bg-opacity, 1));
        }

        .green-txt {
            --tw-bg-opacity: 1;
            color: rgb(34 197 94 / var(--tw-bg-opacity, 1));
        }

        .blue-txt {
            --tw-bg-opacity: 1;
            color: rgb(59 130 246 / var(--tw-bg-opacity, 1));
        }



        @media (max-width: 480px) {
            .recent-activity {
                flex-direction: column;
                align-items: flex-start;
            }

            .recent-activity-right {
                margin-top: 8px;
            }
        }
    </style>

    <div class="layout-container mb-5">
        <!-- LEFT COLUMN -->
        <div class="layout-left">
            <!-- Top row: three small boxes -->
            <div class="top-dashboard   ">
                <!-- Card 1: Due Payments -->
                <a href="Defaulter.aspx" class="card-radius custom-width" style="text-decoration: none; color: inherit;">
                    <div class="card-radius top-card top-purple netlify-color">
                        <div>
                            <h2 style="font-weight:600;">Due Payments</h2>
                            <asp:UpdatePanel runat="server" ID="updatePanelDue" UpdateMode="Conditional">
                                <ContentTemplate>
                                    <asp:HiddenField ID="society_id" runat="server" />
                                    <asp:HiddenField ID="notice_id" runat="server" />
                                    <asp:HiddenField ID="HiddenField4" runat="server" />
                                    <div class="top-value">
                                        ₹
                                        <asp:Label runat="server" ID="lblDue"> </asp:Label>
                                    </div>
                                </ContentTemplate>
                                <Triggers>
                                    <asp:AsyncPostBackTrigger ControlID="due_this_month" EventName="Click" />
                                    <asp:AsyncPostBackTrigger ControlID="due_last_month" EventName="Click" />
                                    <asp:AsyncPostBackTrigger ControlID="due_this_year" EventName="Click" />
                                </Triggers>
                            </asp:UpdatePanel>
                        </div>
                        <div class="top-icon"><i class="fas fa-exclamation-triangle" style="color:#FF0028; font-size:40px"></i></div>
                    </div>
                </a>

                <!-- Card 2: Defaulters -->
                <a href="Defaulter.aspx " class="card-radius custom-width" style="text-decoration: none; color: inherit;">
                    <div class="card-radius top-card top-pink netlify-color">
                        <div>
                            <h2 style="font-weight:600;">Defaulters</h2>
                            <div class="top-value">
                                <asp:Label runat="server" ID="defaulter"> </asp:Label>
                            </div>
                        </div>
                        <div class="top-icon"><i class="fas fa-user-times" style="color:#009217; font-size:40px""></i></div>
                    </div>
                </a>

                <!-- Card 3: Total Members -->
                <a href="owner_search.aspx" class="card-radius custom-width" style="text-decoration: none; color: inherit;">
                    <div class="card-radius top-card top-blue netlify-color">
                        <div>
                            <h2 style="font-weight:600;">Total Members</h2>
                            <div class="top-value">
                                <asp:Label runat="server" ID="residents"> </asp:Label>
                            </div>
                        </div>
                        <div class="top-icon"><i class="fas fa-users" style="color:#000079; font-size:40px""></i></div>
                    </div>
                </a>
            </div>
            <!-- Two big boxes -->

            <div class="card-radius custom-width-container layout-box layout-big layout-green card" id="chartContainer">
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <div style="display: flex; align-items: center; justify-content: space-between;">
                            <div class="header-card">
                                <h6 >Maintenance Tracker</h6>
                            </div>
                            <div class="d-flex mr-4" style="align-items: center; justify-content: space-evenly; gap: 15px;">

                                <%--                                <asp:CheckBox
                                    Checked="true"
                                    ID="CheckBox1"
                                    runat="server"
                                    Text="Regular"
                                    onclick="loadExpenseChart();" />

                                <asp:CheckBox
                                    ID="CheckBox2"
                                    runat="server"
                                    Text="Add"                         
                                    onclick="loadExpenseChart();" />--%>

                                <input type="checkbox" id="CheckBox1" checked="checked">
                                <label for="CheckBox1">Regular</label>

                                <input type="checkbox" id="CheckBox2">
                                <label for="CheckBox2">Add on</label>


                            </div>

                        </div>
                        <div class="divider" style="width: 94%;"></div>

                        <asp:Panel runat="server" ID="lblNoDataFound2" Visible="False">
                            <img src="img/noDataFound2.jpg" style="margin-left: 122px; width: 445px;" />
                        </asp:Panel>



                        <div id="reportsChart"></div>
                    </ContentTemplate>
                </asp:UpdatePanel>
            </div>

            <div class="custom-width-container layout-box layout-big layout-blue d-flex" style="gap: 20px;">
                <div class="card pdc-weekly">
                    <div class="header-card" style="margin-bottom: 10px;">
                        <h6>PDC Clearing</h6>
                    </div>
                    <div class="divider"></div>


                    <div style="width: 100%; overflow: auto;">
                        <asp:Panel ID="lblNoDataFound3" runat="server">
                            <img style="margin-top: 3px; margin-left: 42px; width: 324px;"
                                src="img/noDataFound3.jpg" />
                        </asp:Panel>
                        <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                            <ContentTemplate>
                                <asp:GridView AllowPaging="true" OnPageIndexChanging="GridView1_PageIndexChanging"
                                    PageSize="3" ID="GridView1" runat="server" AutoGenerateColumns="false"
                                    CssClass="" AllowSorting="true" OnSorting="GridView1_Sorting" Width="100%" BorderStyle="None" ShowHeader="False">
                                    <Columns>
                                        <asp:TemplateField>
                                            <ItemTemplate>
                                                <div class="pdc-card-container">
                                                    <div class="pdc-cheque-card">
                                                        <!-- Calendar-style date -->
                                                        <div class="pdc-calendar-box">
                                                            <span>
                                                                <asp:Label CssClass="link-style" ID="che_date" runat="server" Text='<%# Bind("che_date", "{0:MMM}")%>' ForeColor="#1D4ED8"></asp:Label>
                                                            </span>
                                                            <span>
                                                                <asp:Label CssClass="link-style" ID="Label2" runat="server" Text='<%# Bind("che_date", "{0:dd}")%>' ForeColor="#1D4ED8"></asp:Label>
                                                            </span>
                                                        </div>

                                                        <!-- Name and Cheque number -->
                                                        <div class="pdc-details">
                                                            <span class="pdc-name">
                                                                <asp:Label CssClass="link-style" ID="o_name" runat="server" Text='<%# Bind("name")%>'></asp:Label>
                                                            </span>
                                                            <span class="pdc-cheque-number">Cheque #<asp:Label CssClass="link-style" ID="chqno" runat="server" Text='<%# Bind("chqno")%>'></asp:Label>
                                                            </span>
                                                        </div>

                                                        <!-- Cheque Amount -->
                                                        <div class="pdc-amount">
                                                            ₹<asp:Label CssClass="link-style" ID="che_amount" runat="server" Text='<%# Bind("che_amount")%>' ForeColor="#1D4ED8"></asp:Label>
                                                        </div>
                                                    </div>
                                                </div>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                    </Columns>
                                </asp:GridView>

                            </ContentTemplate>
                        </asp:UpdatePanel>
                    </div>
                </div>
                <div class="card pdc-weekly">
                    <div class="header-card">
                        <h6>Weekly Updates</h6>
                    </div>
                    <div class="divider"></div>
                    <div class="card-body update-card">
                        <asp:GridView Width="100%" OnRowCommand="Updates_RowCommand" ID="Updates" runat="server" ShowHeader="false" AutoGenerateColumns="false" GridLines="None" EmptyDataText="No Updates" SelectedRowStyle-Width="100">
                            <Columns>
                              
                                <asp:TemplateField HeaderText="Building" ItemStyle-Width="100%" SortExpression="name">
                                    <ItemTemplate>
                                        <asp:LinkButton
                                            ID="lnkDetails"
                                            runat="server"
                                            CommandName="Redirect"
                                            CommandArgument='<%# Eval("type") %>'
                                            Style="text-decoration: none;">
                                            <div class=" d-flex update-grid hov" style="gap: 12px;">
                                                <asp:Image runat="server" Width="35px" Height="39px"
                                                    ImageUrl='<%# Eval("ImageUrl") %>'
                                                    AlternateText="Type Image" />
                                                <div>
                                                    <div class="inner-div">
                                                        <asp:Label runat="server" ID="Label1" Text='<%# Eval("type") %>' Font-Size="Small" ForeColor="#808080"></asp:Label>
                                                        <asp:Label runat="server" Text='<%# Eval("date", "{0:yyyy-MM-dd}") %>' Font-Size="Small" ForeColor="#BCBED0"></asp:Label>
                                                    </div>
                                                    <div class="notify-div">
                                                        <asp:Label runat="server" ID="name" Text='<%# Eval("name") %>' ForeColor="Black"></asp:Label>
                                                    </div>

                                                </div>
                                            </div>

                                        </asp:LinkButton>
                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                        </asp:GridView>
                        <asp:Panel ID="noUpdates4" runat="server" Style="margin: auto;">
                            <img style="width: 285px; margin-left: 70px;"
                                src="img/noUpdates.jpg" />
                        </asp:Panel>
                    </div>
                </div>
            </div>
        </div>

        <!-- RIGHT COLUMN -->

        <div class="layout-right">

            <div class="card custom-width-container layout-box layout-tall layout-purple card-radius">
                <div class="header-card">
                    <h6>Recent Activity</h6>
                </div>
                <div class="divider"></div>
                <div style="height: 226px; overflow: auto; padding: 0 5px;">
                    <div>
                        <asp:GridView Width="100%" OnRowCommand="Updates_RowCommand" ID="Recent_activity" runat="server" ShowHeader="false" AutoGenerateColumns="false" GridLines="None" EmptyDataText="No Updates" SelectedRowStyle-Width="100">
                            <Columns>

                                <asp:TemplateField HeaderText="Building" ItemStyle-Width="100%" SortExpression="name">
                                    <ItemTemplate>
                                        <div class="recent-container">
                                            <div class="recent-activity">
                                                <div class="recent-activity-left">

                                                    <%--  <asp:Literal ID="IconLiteral" runat="server"
                                                        Text='<%# Eval("received_amt").ToString() == "0.00" ? "<i class=\"fas fa-tools text-white\"></i>" : "<i class=\"fas fa-check text-white\"></i>" %>'>
                                                    </asp:Literal>--%>

                                                    <div class='<%# Eval("paid_amount").ToString() == "0.00" ? "recent-icon blue-bg" : "recent-icon green-bg" %>'>
                                                        <i class='<%# Eval("paid_amount").ToString() == "0.00" ? "fas fa-tools text-white" : "fas fa-check text-white" %>'></i>
                                                    </div>


                                                    <div class="recent-details">
                                                        <div class="recent-text">
                                                            <asp:Label CssClass="link-style" ID="Label1" runat="server" Text='<%# Bind("particular")%>' Font-Size="14px"></asp:Label>
                                                        </div>
                                                        <div class="recent-time">
                                                            <asp:Label CssClass="link-style" ID="Label3" runat="server" Text='<%# Bind("timestamp")%>' Font-Size="12px" ForeColor="#9B9B9B"></asp:Label>
                                                        </div>
                                                    </div>
                                                </div>
                                                <div class="recent-activity-right recent-amount">
                                                    <asp:Label CssClass='<%# Eval("paid_amount").ToString() == "0.00" ? "link-style blue-txt" : "link-style green-txt" %>' ID="Label2" runat="server" Text='<%# Eval("paid_amount").ToString() == "0.00"?Eval("date", "{0:MMM-dd}"):Eval("paid_amount")%>'></asp:Label>
                                                </div>
                                            </div>
                                        </div>

                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                        </asp:GridView>
                        <a class="pl-2 pb-2" href="recent_activity.aspx">See All</a>
                    </div>
                </div>
            </div>

            <asp:UpdatePanel runat="server" ID="updatePanelDonat" UpdateMode="Conditional">
                <ContentTemplate>
                    <div class="card-radius custom-width-container card layout-box layout-medium layout-pink">
                        <div style="display: flex; align-items: center; justify-content: space-between;">
                            <div class="header-card">
                                <h6>Income Tracker</h6>
                            </div>
                            <div class="dropdown no-arrow mr-4">
                                <a class="dropdown-toggle" href="#" role="button" id="dropdownMenuLink" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                                    <i class="fas fa-ellipsis-v fa-sm fa-fw text-gray-400"></i>
                                </a>
                                <div class="dropdown-menu dropdown-menu-right shadow animated--fade-in" aria-labelledby="dropdownMenuLink">
                                    <asp:Button ID="due_this_month" runat="server" CssClass="dropdown-item" Text="This Month" OnClick="due_this_month_Click"></asp:Button>
                                    <asp:Button ID="due_last_month" runat="server" CssClass="dropdown-item" Text="Last Month" OnClick="due_last_month_Click"></asp:Button>
                                    <asp:Button ID="due_this_year" runat="server" CssClass="dropdown-item" Text="This Year" OnClick="due_this_year_Click"></asp:Button>
                                </div>
                            </div>
                        </div>

                        <div class="divider"></div>
                        <div class="card-body d-flex flex-column align-items-center justify-content-center">
                            <asp:Label ID="lblNoData" runat="server"><img src="img/noDataFound.jpg" width="233px"/></asp:Label>



                            <asp:Chart ID="Chart1" runat="server" BackColor="Transparent">
                                <Series>
                                    <asp:Series Name="Default" ChartType="Doughnut"
                                        IsValueShownAsLabel="false"
                                        Label="#PERCENT{P1}"
                                        ToolTip="#VALX: ₹#VALY"
                                        Font="Segoe UI, 9pt"
                                        LabelForeColor="White">
                                    </asp:Series>
                                </Series>

                                <ChartAreas>
                                    <asp:ChartArea Name="ChartArea1" BackColor="Transparent">
                                        <Area3DStyle Enable3D="true" LightStyle="Realistic" />
                                        <AxisX LineWidth="0" MajorGrid-Enabled="False" LabelStyle-Enabled="False" />
                                        <AxisY LineWidth="0" MajorGrid-Enabled="False" LabelStyle-Enabled="False" />
                                    </asp:ChartArea>
                                </ChartAreas>


                            </asp:Chart>

                            <asp:Panel ID="chartDots" runat="server">
                                <div class="mt-4 text-center small">
                                    <span class="mr-2">
                                        <i class="fas fa-circle  mr-1" style="color: #6266F1;"></i>Due
                                    </span>
                                    <span class="mr-2">
                                        <i class="fas fa-circle mr-1" style="color: #A6B4FD;"></i>Collection
                                    </span>
                                </div>
                            </asp:Panel>

                        </div>



                    </div>
                </ContentTemplate>
            </asp:UpdatePanel>
            <asp:Timer ID="SharedTimer" runat="server" Interval="1000" OnTick="TimerNotif_Tick" />
            <div class="card custom-width-container card-radius layout-box layout-small-right layout-cyan">
                <a href="support_ticket.aspx" style="text-decoration: none;">
                    <div class="header-card">
                        <h6>HelpDesk Ticket</h6>
                    </div>
                    <div class="divider"></div>

                    <div class="card-body form-group">
                        <asp:UpdatePanel ID="upNotifCount" runat="server" UpdateMode="Conditional">
                            <ContentTemplate>
                                <div class="helpdesk-cards">
                                    <div class="helpdesk-card">
                                        <div class="helpdesk-card-title">Open Ticket</div>
                                        <div class="helpdesk-card-number">
                                            <asp:Label ID="open" runat="server" Text="Open" ForeColor="Black"></asp:Label>
                                        </div>
                                    </div>
                                    <div class="helpdesk-card">
                                        <div class="helpdesk-card-title">Resolve Tickets</div>
                                        <div class="helpdesk-card-number">
                                            <asp:Label ID="resolved" runat="server" Text="Resolved" ForeColor="Black"></asp:Label>
                                        </div>

                                    </div>
                                    <asp:Label ID="lblToken" runat="server" Text=""></asp:Label>

                                </div>
                            </ContentTemplate>
                            <Triggers>
                                <asp:AsyncPostBackTrigger ControlID="SharedTimer" EventName="Tick" />
                            </Triggers>

                        </asp:UpdatePanel>
                        <br />

                    </div>
                </a>
            </div>
            <asp:Label runat="server" ID="hiddenJson" Visible="false"></asp:Label>



        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/apexcharts"></script>
    <script>
        //Sys.Application.add_load(loadExpenseChart());
        let chartInstance = null;

        function getSelectedCheckboxValue() {
            const checkbox1 = document.getElementById('CheckBox1');
            const checkbox2 = document.getElementById('CheckBox2');

            const isChecked1 = checkbox1.checked;
            const isChecked2 = checkbox2.checked;

            if (isChecked1 && isChecked2) return 2;
            if (isChecked1) return 1;
            if (isChecked2) return 0;

            return 3; // fallback
        }

        function loadExpenseChart() {
            const selectedValue = getSelectedCheckboxValue();

            fetch('TokenService.asmx/getJson', {
                method: 'POST',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ a: selectedValue })
            })
                .then(response => response.json())
                .then(data => {
                    try {
                       
                        const parsed = JSON.parse(data.d);
                        
                        const months = parsed.map(item => item.expense_month);
               
                        const expenseData = parsed.map(item => item.expense);
                        const dueData = parsed.map(item => item.Due);
                        const collectionData = parsed.map(item => item.Collection);

                        const options = {
                            series: [
                                { name: 'Due', data: dueData },
                                { name: 'Collection', data: collectionData },
                                { name: 'Total', data: expenseData }
                            ],
                            chart: {
                                height: 350,
                                type: 'area',
                                toolbar: { show: false }
                            },
                            markers: { size: 4 },
                            colors: ['#ffc107', '#28a745', '#4154f1',],
                            fill: {
                                type: "gradient",
                                gradient: {
                                    shadeIntensity: 1,
                                    opacityFrom: 0.3,
                                    opacityTo: 0.4,
                                    stops: [0, 90, 100]
                                }
                            },
                            dataLabels: { enabled: false },
                            stroke: { curve: 'smooth', width: 2 },
                            xaxis: {
                                type: 'category',
                                categories: months
                            },
                            tooltip: {
                                x: { format: 'MMM' }
                            }
                        };

                        // Destroy existing chart before creating a new one
                        if (chartInstance) {
                            chartInstance.destroy();
                        }

                        chartInstance = new ApexCharts(document.querySelector("#reportsChart"), options);
                        chartInstance.render();

                    } catch (err) {
                    }
                })
                .catch(error => {
                });
        }

        // Add onchange listeners and load initial chart
        window.addEventListener("load", () => {
            document.getElementById('CheckBox1').addEventListener('change', loadExpenseChart);
            document.getElementById('CheckBox2').addEventListener('change', loadExpenseChart);

            loadExpenseChart();
        });


    </script>

    <script src="https://www.gstatic.com/firebasejs/9.6.10/firebase-app-compat.js"></script>
    <script src="https://www.gstatic.com/firebasejs/9.6.10/firebase-messaging-compat.js"></script>
    <script type="text/javascript">

            console.log("hello")
        firebase.initializeApp({
            apiKey: "AIzaSyCVD6hUSK4zMfG43bMjyjwTFmTz5PJc_qk",
            authDomain: "society-management-32053.firebaseapp.com",
            projectId: "society-management-32053",
            storageBucket: "society-management-32053.appspot.com",
            messagingSenderId: "303424747645",
            appId: "1:303424747645:web:a10ad8eceb38c4fe10d914",
            measurementId: "G-MCRPPNVW38"
        });

        const messaging = firebase.messaging();
        Notification.requestPermission().then(permission => {
            if (permission === "granted") {
                navigator.serviceWorker.register('/firebase-messaging-sw.js')
                    .then((registration) => {

                        //messaging.useServiceWorker(registration); // only works with compat SDK

                        return messaging.getToken({
                            vapidKey: "BKJDUyImlBxO4O_UewJxcN8Ug0EdqxsmxbwQ8nn2bscwwWBUGPGsuMdlU9IKvuTe60iz59iJC0wBMfGuXRkqj2E",
                            serviceWorkerRegistration: registration
                        });
                    })
                    .then(token => {

                        console.log(token)
                        sendTokenToServer(token);
                    })
                    .catch(error => {
                    });
            } else {
            }
        });

        function sendTokenToServer(token) {
            fetch('TokenService.asmx/SaveToken', {
                method: 'POST',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ token: token })
            })
                .then(response => response.json())
                .then(data => {

                })
                .catch(error => {
                });
        }

    </script>

</asp:Content>

