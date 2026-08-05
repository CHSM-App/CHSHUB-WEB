<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Messages_master.aspx.cs" Inherits="Society2024.Messages_master" MasterPageFile="~/Site.Master" %>


<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="ajaxToolkit" %>

<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
    <style>
        .resized-model {
            width: 700px;
            height: auto;
            right: 82px;
        }

        @media(max-width: 431px) {
            .resized-model {
                height: auto;
                margin: auto;
                width: 300px;
                margin-top: 168px;
                right: 1px;
            }
        }

        .nav .nav-link {
            cursor: pointer;
        }


        /*        .input-buttons {
            position: absolute;
            right: 10px;
            top: 50%;
            transform: translateY(-50%);
        }



        .search-button2:hover {
            color: #0056b3;*/
        }
    </style>

    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

    <div class="box box-primary">
        <div class="box-header with-border">
            <div class="box-body">
                <table width="100%">
                    <tr>
                        <th width="100%">
                            <h1 class="font-weight-bold" style="color: #012970;">Messages</h1>
                        </th>
                    </tr>
                </table>

                <!-- ✅ Search & Add Button Section -->
                <div class="form-group">
                    <div class="row">
                        <div class="col-12">
                            <div class="top-row d-flex align-items-center">
                                <div class="search-container">

                                    <asp:TextBox
                                        ID="txt_search"
                                        CssClass="aspNetTextBox"
                                        placeHolder="Search here"
                                        runat="server"
                                        TextMode="Search"
                                        AutoPostBack="true"
                                        OnTextChanged="btn_search_Click"
                                         onkeyup="filterTable()" />

                                    <ajaxToolkit:CalendarExtender
                                        ID="CalendarExtender1"
                                        runat="server"
                                        TargetControlID="txt_search"
                                        PopupButtonID="btn_calendar"
                                        Format="yyyy-MM-dd" />

                                    <!-- Calendar and Search Buttons -->
                                    <div class="input-buttons">
                                        <img
                                            id="btn_calendar"
                                            src="img/calendar.png"
                                            alt="Pick Date"
                                            class="calendar-icon"
                                            style="cursor: pointer;" />
                                        <button
                                            id="btn_search"
                                            type="submit"
                                            class="search-button2"
                                            runat="server"
                                            onserverclick="btn_search_Click">
                                            <span class="material-symbols-outlined">search</span>
                                        </button>
                                    </div>
                                </div>



                            </div>
                        </div>

                    </div>
                </div>


                <!-- Tabs -->
                <%--                <asp:HiddenField ID="hfFilter" runat="server" />
                <ul class="nav nav-tabs mb-3">
                    <li class="nav-item">
                        <asp:LinkButton ID="btnAll" runat="server" CssClass="nav-link active" OnClick="btnAll_Click">All Messages</asp:LinkButton>
                    </li>
                    <li class="nav-item">
                        <asp:LinkButton ID="btnResidents" runat="server" CssClass="nav-link" OnClick="btnResidents_Click">Residents</asp:LinkButton>
                    </li>
                    <li class="nav-item">
                        <asp:LinkButton ID="btnStaff" runat="server" CssClass="nav-link" OnClick="btnStaff_Click">Staff</asp:LinkButton>
                    </li>
                </ul>--%>

                <!-- Grid -->
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <div class="form-group">
                            <div class="row">
                                <div class="col-sm-12">
                                    <div style="width: 100%; overflow: auto;" class="table-container ">
                                        <asp:GridView ID="GridView1" runat="server" AutoGenerateColumns="false"
                                            CssClass="table table-bordered table-hover table-striped"
                                            AllowPaging="true" PageSize="10"
                                            OnPageIndexChanging="GridView1_PageIndexChanging"
                                            OnRowCommand="GridView1_RowCommand"
                                            EmptyDataText="No Messages Found">
                                            <Columns>
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:BoundField DataField="r_id" HeaderText="ID" Visible="false" />
                                                <asp:BoundField DataField="owner_name" HeaderText="Sender" />
                                                <asp:BoundField DataField="message_sub" HeaderText="Subject" />
                                                <asp:BoundField DataField="date" HeaderText="Date" DataFormatString="{0:dd/MM/yyyy}" />

                                                <asp:TemplateField HeaderText="Actions">
                                                    <ItemTemplate>
                                                        <asp:LinkButton ID="btnView" runat="server" CssClass="btn btn-info btn-sm"
                                                            CommandName="ViewMsg" CommandArgument='<%# Eval("r_id") %>'>
                                                            View
                                                        </asp:LinkButton>
                                                        &nbsp;
                                                     <%--   <asp:LinkButton ID="btnDelete" runat="server" CssClass="btn btn-danger btn-sm"
                                                            CommandName="DeleteMsg" CommandArgument='<%# Eval("r_id") %>'
                                                            OnClientClick="return confirm('Are you sure you want to delete this message?');">
                                                            Delete
                                                        </asp:LinkButton>--%>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                            </Columns>
                                        </asp:GridView>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </ContentTemplate>
                </asp:UpdatePanel>
            </div>
        </div>
    </div>



    <!-- View Modal (read-only) -->
    <div class="modal fade" id="viewModal" tabindex="-1" role="dialog" aria-labelledby="viewModalLabel" data-backdrop="static">
        <div class="modal-dialog">
            <div class="modal-content resized-model">
                <div class="modal-header">
                    <h4 class="modal-title"><strong>Message Details</strong></h4>
                    <button type="button" class="close" data-dismiss="modal">&times;</button>
                </div>
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>


                <div class="modal-body">
                    <p><strong>Sender: </strong>
                        <asp:Label ID="lblSenderName" runat="server" /></p>

                    <p><strong>Date: </strong>
                        <asp:Label ID="lblDate" runat="server" /></p>
                    <p><strong>Subject: </strong>
                        <asp:Label ID="lblSubject" runat="server" /></p>

                    <div class="form-group">
                        <label><strong>Message</strong></label>
                        <asp:TextBox ID="txtMessageBody" runat="server" TextMode="MultiLine" CssClass="form-control" ReadOnly="true" Rows="6" />
                    </div>
                </div>

                                            </ContentTemplate>
                    <Triggers>
                        <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                    </Triggers>
                </asp:UpdatePanel>
                <div class="modal-footer">
                    <asp:Button ID="btnCloseModal" runat="server" Text="Close" CssClass="btn btn-secondary" OnClientClick="$('#viewModal').modal('hide'); return false;" />
                </div>
            </div>
        </div>
    </div>

    <script type="text/javascript">

        // Search and Filter Functions
        function filterTable() {
            const input = document.getElementById('<%= txt_search.ClientID %>');
            if (!input) return;

            const filter = input.value.toLowerCase();
            const table = document.querySelector('.table-container table');

            if (!table) return;

            const rows = table.getElementsByTagName('tr');

            for (let i = 1; i < rows.length; i++) {
                const row = rows[i];
                const cells = row.getElementsByTagName('td');
                let found = false;

                for (let j = 0; j < cells.length - 1; j++) {
                    const cell = cells[j];
                    if (cell && cell.textContent.toLowerCase().indexOf(filter) > -1) {
                        found = true;
                        break;
                    }
                }

                row.style.display = found ? '' : 'none';
            }
        }
        function SuccessDelete() {
            Swal.fire({
                title: 'Deleted',
                text: 'Message deleted successfully.',
                icon: 'success',
                timer: 1400,
                showConfirmButton: false
            });
        }
        function FailedEntry() {
            Swal.fire({
                title: 'Error',
                text: 'Operation failed. Please try again.',
                icon: 'error'
            });
        }
    </script>


</asp:Content>
