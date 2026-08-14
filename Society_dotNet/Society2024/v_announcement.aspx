<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="v_announcement.aspx.cs" Inherits="Society.v_announcement" MasterPageFile="~/Site.Master" %>
<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
	<style>
		.tab-content {
			padding : 20px 0;
		}
	</style>

	<table width="100%">
		<tr>
			<th width="100%" class="">
				<h1 class=" tex0 font-weight-bold " style="color: #012970;">Announcements
				</h1>
			</th>
		</tr>
	</table>

	<div class="form-group">
		<div class="row">
			<div class="col-12">
				<div class="d-flex align-items-center">
					<div class="search-container">

						<asp:TextBox ID="txt_search" CssClass="aspNetTextBox" placeHolder="Search here" runat="server" TextMode="Search" AutoPostBack="true" autocomplete="off" onkeyup="filterTable()" />

						<!-- Calendar and Search Buttons -->
						<div class="input-buttons">
							<button id="btn_search" type="submit" class="search-button2" runat="server" onclick="filterTable()">
								<span class="material-symbols-outlined">search</span>
							</button>
						</div>
					</div>
					&nbsp;&nbsp;

					<button type="button" class="btn btn-primary" data-toggle="modal" data-target="#addAnnouncementModal">
						<i class="fas fa-plus"></i>Add Announcement
					</button>
				</div>
			</div>
		</div>
	</div>


	<div class="containerr mt-4">
		<!-- Tabs Navigation -->
		<ul class="nav nav-tabs" id="announcementTabs" role="tablist">
			<li class="nav-item">
				<a class="nav-link active" id="general-tab" data-toggle="tab" href="#general" role="tab">General Announcements
				</a>
			</li>
			<li class="nav-item">
				<a class="nav-link" id="meeting-tab" data-toggle="tab" href="#meeting" role="tab">Meeting Updates
				</a>
			</li>
			<li class="nav-item">
				<a class="nav-link" id="workbudget-tab" data-toggle="tab" href="#workbudget" role="tab">Work & Budget Information
				</a>
			</li>
		</ul>

		<!-- Tab Content -->
		<div class="tab-content" id="announcementTabsContent">
			<!-- General Announcements Tab -->
			<div class="tab-pane fade show active" id="general" role="tabpanel">
				<div class="gridview-container">
					<asp:GridView ID="gvGeneral" runat="server" CssClass="table table-bordered table-striped" AutoGenerateColumns="False">
						<Columns>
							<asp:BoundField DataField="AnnouncementId" HeaderText="ID" />
							<asp:BoundField DataField="Title" HeaderText="Title" />
							<asp:BoundField DataField="Description" HeaderText="Description" />
							<asp:BoundField DataField="Date" HeaderText="Date" DataFormatString="{0:MM/dd/yyyy}" />
							<asp:BoundField DataField="Category" HeaderText="Category" />
							<asp:TemplateField HeaderText="Action" Visible="false">
								<ItemTemplate>
									<asp:Button runat="server" CssClass="btn btn-sm btn-info" Text="View" OnClick="btnView_Click" CommandArgument='<%# Eval("AnnouncementId") %>' />
								</ItemTemplate>
							</asp:TemplateField>
						</Columns>
					</asp:GridView>
				</div>
			</div>

			<!-- Meeting Updates Tab -->
			<div class="tab-pane fade" id="meeting" role="tabpanel">
				<div class="gridview-container">
					<asp:GridView ID="gvMeeting" runat="server" CssClass="table table-bordered table-striped" AutoGenerateColumns="False">
						<Columns>
							<asp:BoundField DataField="AnnouncementId" HeaderText="ID" />
							<asp:BoundField DataField="Title" HeaderText="Title" />
							<asp:BoundField DataField="Description" HeaderText="Description" />
							<asp:BoundField DataField="Date" HeaderText="Date" DataFormatString="{0:MM/dd/yyyy}" />
							<asp:BoundField DataField="Category" HeaderText="Category" />
							<asp:TemplateField HeaderText="Action" Visible="false">
								<ItemTemplate>
									<button type="button" class="btn btn-sm btn-info">View</button>
								</ItemTemplate>
							</asp:TemplateField>
						</Columns>
					</asp:GridView>
				</div>
			</div>

			<!-- Work & Budget Information Tab -->
			<div class="tab-pane fade" id="workbudget" role="tabpanel">
				<div class="gridview-container">
					<asp:GridView ID="gvWorkBudget" runat="server" CssClass="table table-bordered table-striped" AutoGenerateColumns="False">
						<Columns>
							<asp:BoundField DataField="AnnouncementId" HeaderText="ID" />
							<asp:BoundField DataField="Title" HeaderText="Title" />
							<asp:BoundField DataField="Description" HeaderText="Description" />
							<asp:BoundField DataField="Date" HeaderText="Date" DataFormatString="{0:MM/dd/yyyy}" />
							<asp:BoundField DataField="Category" HeaderText="Category" />
							<asp:TemplateField HeaderText="Action" Visible="false">
								<ItemTemplate>
									<button type="button" class="btn btn-sm btn-info">View</button>
								</ItemTemplate>
							</asp:TemplateField>
						</Columns>
					</asp:GridView>
				</div>
			</div>
		</div>
	</div>

	<!-- Add Announcement Modal -->
	<div class="modal fade" id="addAnnouncementModal" tabindex="-1" role="dialog">
		<div class="modal-dialog" role="document">
			<div class="modal-content">
				<div class="modal-header">
					<h5 class="modal-title">Add New Announcement</h5>
					<button type="button" class="close" data-dismiss="modal">
						<span>&times;</span>
					</button>
				</div>
				<div class="modal-body">
					<div class="form-group">
						<label for="ddlCategory">Category</label>
						<asp:DropDownList ID="ddlCategory" runat="server" CssClass="form-control">
							<asp:ListItem Value="General">General</asp:ListItem>
							<asp:ListItem Value="Meeting">Meeting</asp:ListItem>
							<asp:ListItem Value="WorkBudget">WorkBudget</asp:ListItem>
						</asp:DropDownList>
					</div>
					<div class="form-group">
						<label for="txtTitle">Title</label>
						<asp:TextBox ID="txtTitle" runat="server" CssClass="form-control" placeholder="Enter announcement title"></asp:TextBox>
					</div>
					<div class="form-group">
						<label for="txtDescription">Description</label>
						<asp:TextBox ID="txtDescription" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="4" placeholder="Enter description"></asp:TextBox>
					</div>
					<div class="form-group">
						<label for="txtDate">Date</label>
						<asp:TextBox ID="txtDate" runat="server" CssClass="form-control" TextMode="Date"></asp:TextBox>
					</div>
				</div>
				<div class="modal-footer">
					<button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
					<asp:Button ID="btnSave" runat="server" CssClass="btn btn-primary" Text="Save Announcement" OnClick="btnSave_Click" />
				</div>
			</div>
		</div>
	</div>
</asp:Content>