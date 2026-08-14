<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Charges.aspx.cs" Inherits="Society.Charges" MasterPageFile="~/Site.Master" %>

<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">

    <link href="https://code.jquery.com/ui/1.13.2/themes/base/jquery-ui.css" rel="stylesheet" />
    <script src="https://code.jquery.com/ui/1.13.2/jquery-ui.min.js"></script>
    <body>
        <div class="box box-primary">
            <div class="box-header with-border">

                <div class="box-body">
                    <table width="100%">
                        <tr>
                            <th width="100%" class="">
                                <h1 class=" text font-weight-bold " style="color: #012970;">Maintenance Charges
                                </h1>
                            </th>
                        </tr>
                    </table>


                    <div class="form-group">
                        <div class="row">
                            <div class="col-12">
                                <div class="d-flex align-items-center">
                                    <div class="search-container">

                                        <asp:TextBox
                                            ID="txt_search"
                                            CssClass="aspNetTextBox"
                                            placeHolder="Search here"
                                            runat="server"
                                            TextMode="Search"                                                                                     
                                            autocomplete="off"
                                            onkeyup="triggerSearch()"/>

                                        <!-- Calendar and Search Buttons -->    
                                        <div class="input-buttons">
                                            <button
                                                id="btn_search"
                                                type="button"
                                                class="search-button2"                                                 
                                                onclick="filterTable()">
                                                <span class="material-symbols-outlined">search</span>
                                            </button>
                                        </div>
                                    </div>

                                    &nbsp;&nbsp;
                                <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#edit_modal">Add</button>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div style="overflow:visible" class="g-Table">

                    <asp:GridView ID="GridView1" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped"
                        AllowSorting="true" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" HeaderStyle-BackColor="lightblue"
                        AllowPaging="true"
                        PageSize="10">
                         <HeaderStyle BackColor="lightblue" CssClass="sticky-header" />
                        <Columns>
                            <asp:TemplateField HeaderText="No" ItemStyle-Width="30">
                                <ItemTemplate>
                                    <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="Charges" ItemStyle-Width="30">
                                <ItemTemplate>
                                    <asp:Label ID="lblNature" Text='<%# Bind("NatureOfCharge") %>' runat="server" />
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="Amount" ItemStyle-Width="30">
                                <ItemTemplate>
                                    <asp:Label ID="lblAmount" Text='<%# Bind("Amount") %>' runat="server" />
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="Date" ItemStyle-Width="30">
                                <ItemTemplate>
                                    <asp:Label ID="lblDate" Text='<%# Bind("Date") %>' runat="server" />
                                </ItemTemplate>    
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="Status" ItemStyle-Width="30">
                                <ItemTemplate>
                                    <asp:Label ID="lblStatus" Text='<%# Convert.ToInt32(Eval("status")) == 1 ? "Active" : "Inactive" %>' runat="server" />
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="Edit" ItemStyle-Width="30">
                                <ItemTemplate>
                                    <asp:LinkButton runat="server" ID="edit" OnCommand="edit_Command" CommandArgument='<%# Bind("charge_id")%>'>
                                       <img src="Images/123.png" /></asp:LinkButton>
                                </ItemTemplate>
                            </asp:TemplateField>
                        </Columns>
                    </asp:GridView>
                        </div>

                    <div class="modal fade bs-example-modal-sm" id="edit_modal" tabindex="-1" role="dialog" aria-labelledby="myLargeModalLabel" data-backdrop="static" >
                        <div class="modal-dialog modal-sm-4">

                            <div class="modal-content resized-model">
                                <div class="modal-header">
                                    <h4 class="modal-title"><strong>Add Charges</strong></h4>
                                </div>


                                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>
                                        <asp:HiddenField runat="server" ID="charge_id"/>


                                        <div class="modal-body" style="min-width:400px">
                                            <div class="form-group">
                                                <label for="txtNatureOfCharge"><strong>Nature of Charge:</strong></label>
                                                <asp:TextBox ID="txtNatureOfCharge" runat="server" CssClass="form-control" required="required" placeholder="Enter nature of charge"></asp:TextBox>
                                            </div>

                                            <div class="form-group mt-3">
                                                <label for="txtAmount"><strong>Amount:</strong></label>
                                                <asp:TextBox ID="txtAmount" runat="server" CssClass="form-control" required="required" placeholder="Enter amount" TextMode="Number"></asp:TextBox>
                                            </div>



                                            <div class="form-group mt-3">
                                                <label for="txtAmount"><strong>Bill type:</strong></label>
                                                <asp:DropDownList ID="ddlType" runat="server" CssClass="form-control" OnSelectedIndexChanged="dueDate_SelectedIndexChanged" AutoPostBack="true">
                                                    <asp:ListItem Text="Regular" Value="1"></asp:ListItem>
                                                    <asp:ListItem Text="Add-on" Value="0"></asp:ListItem>
                                                </asp:DropDownList>
                                            </div>

                                        </div>

                                    </ContentTemplate>
                                    <Triggers>
                                        <asp:AsyncPostBackTrigger ControlID="ddlType" EventName="SelectedIndexChanged" />
                                    </Triggers>
                                </asp:UpdatePanel>

                                <div class="modal-footer">
                                    <div class="form-group">
                                        <div class="row">
                                            <center>
                                                <asp:Button
                                                    ID="btnUploadExcel"
                                                    runat="server"
                                                    Text="Save"
                                                    CssClass="btn btn-primary"
                                                    OnClick="btn_save_Click"
                                                    OnClientClick="disableSaveButtonIfValid();" />

                                                <asp:Button
                                                    ID="Button1"
                                                    runat="server"
                                                    Text="Close"
                                                    CssClass="btn btn-secondary"
                                                    UseSubmitBehavior="False"
                                                    OnClientClick="resetForm(); return false;"
                                                    data-dismiss="modal" />
                                            </center>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <%-----------------modal end------------------%>
                </div>
            </div>
        </div>


        <script>

            function filterTable() {
                const input = document.getElementById('<%= txt_search.ClientID %>');
                if (!input) return;

                const filter = input.value.toLowerCase();
                const table = document.querySelector('.g-Table table');

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

            function triggerSearch() {
                var btn = document.getElementById('btn_search');
                if (btn) {
                    btn.click();
                }
            }


            function disableSaveButtonIfValid() {
                var btn = document.getElementById('<%= btnUploadExcel.ClientID %>');
                var modal = document.getElementById('edit_modal');
                var inputs = modal.querySelectorAll('input[required], select[required]');
                var allValid = true;

                inputs.forEach(function (input) {
                    if (!input.checkValidity()) {
                        allValid = false;
                    }
                });

                if (allValid && btn) {
                    btn.disabled = true;
                    btn.value = "Saving...";


                    __doPostBack('<%= btnUploadExcel.UniqueID %>', '');

                    return false; // prevent default to avoid double postback
                }

                return false; // prevent postback if not valid
            }
        </script>
    </body>




</asp:Content>
