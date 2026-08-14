<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="v_resident.aspx.cs" Inherits="Society.v_resident" MasterPageFile="~/Site.Master" %>

<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
    <style>
        .grid-wrapper {
            overflow-x: auto;
            margin-top: 20px;
        }
         
        .bill-grid {
            width: 100%;
            border-collapse: collapse;
        }

            .bill-grid th {
                background-color: #2c5282;
                color: white;
                padding: 12px;
                text-align: left;
                font-weight: bold;
            }

            .bill-grid td {
                padding: 10px;
                border: 1px solid #ddd;
            }

            .bill-grid tr:nth-child(even) {
                background-color: #f9f9f9;
            }

            .bill-grid tr:hover {
                background-color: #f0f0f0;
            }

            .bill-grid input[type="text"] {
                width: 90%;
                padding: 6px;
                border: 1px solid #ccc;
                border-radius: 4px;
            }

        .btn-update {
            background-color: #2196F3;
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
        }

            .btn-update:hover {
                background-color: #0b7dda;
            }

        .btn-save-all {
            background-color: #4CAF50;
            color: white;
            border: none;
            padding: 12px 30px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
            margin-top: 20px;
        }

            .btn-save-all:hover {
                background-color: #45a049;
            }

        /* Decorative Button Styles */
        .btn-edit {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            padding: 8px 20px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
            transition: all 0.3s ease;
            box-shadow: 0 4px 6px rgba(102, 126, 234, 0.3);
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

            .btn-edit:hover {
                transform: translateY(-2px);
                box-shadow: 0 6px 12px rgba(102, 126, 234, 0.4);
                background: linear-gradient(135deg, #764ba2 0%, #667eea 100%);
            }

            .btn-edit:active {
                transform: translateY(0);
                box-shadow: 0 2px 4px rgba(102, 126, 234, 0.3);
            }

        .btn-update {
            background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%);
            color: white;
            border: none;
            padding: 8px 20px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
            transition: all 0.3s ease;
            box-shadow: 0 4px 6px rgba(17, 153, 142, 0.3);
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

            .btn-update:hover {
                transform: translateY(-2px);
                box-shadow: 0 6px 12px rgba(17, 153, 142, 0.4);
                background: linear-gradient(135deg, #38ef7d 0%, #11998e 100%);
            }

            .btn-update:active {
                transform: translateY(0);
                box-shadow: 0 2px 4px rgba(17, 153, 142, 0.3);
            }

        .btn-cancel {
            background: linear-gradient(135deg, #fc4a1a 0%, #f7b733 100%);
            color: white;
            border: none;
            padding: 8px 20px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
            transition: all 0.3s ease;
            box-shadow: 0 4px 6px rgba(252, 74, 26, 0.3);
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

            .btn-cancel:hover {
                transform: translateY(-2px);
                box-shadow: 0 6px 12px rgba(252, 74, 26, 0.4);
                background: linear-gradient(135deg, #f7b733 0%, #fc4a1a 100%);
            }

            .btn-cancel:active {
                transform: translateY(0);
                box-shadow: 0 2px 4px rgba(252, 74, 26, 0.3);
            }

        .total-amount {
            font-weight: bold;
            color: #4CAF50;
        }
    </style>
    <body>
        <div class="box box-primary">
            <div class="box-header with-border">

                <div class="box-body">
                    <table width="100%">
                        <tr>
                            <th width="100%" class="">
                                <h1 class=" tex0 font-weight-bold " style="color: #012970;">Village Resident Details
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
                                            onkeyup="triggerSearch()" />

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
                                        <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#addHouseModal">Add</button>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="containerr">

                        <div style="width: 100%; overflow: visible;"  class="grid-wrapper">
                            <asp:GridView ID="GridViewBills" 
                                runat="server"
                                
                                CssClass="table table-striped table-bordered"
                                AutoGenerateColumns="False"
                                AllowSorting="true"
                                OnSorting="GridViewBills_Sorting"
                                OnRowEditing="GridViewBills_RowEditing"
                                OnRowCancelingEdit="GridViewBills_RowCancelingEdit"
                                OnRowUpdating="GridViewBills_RowUpdating"
                                DataKeyNames="house_id">
                                <HeaderStyle BackColor="lightblue" CssClass="sticky-header" />
                                <Columns>
                                    <asp:BoundField DataField="house_id" HeaderText="ID" ReadOnly="True" Visible="False"/>

                                    <asp:TemplateField HeaderText="Owner Name" Visible="false">
                                        <EditItemTemplate>
                                            <asp:TextBox ID="txt_o_id" runat="server" Text='<%# Bind("village_owner_id") %>'></asp:TextBox>
                                            <asp:Label ID="lbl_o_id" runat="server" Text='<%# Eval("village_owner_id") %>'></asp:Label>
                                        </EditItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="Owner Name" SortExpression="name">
                                        <ItemTemplate>
                                            <asp:Label ID="lblOwnerName" runat="server" Text='<%# Eval("name") %>'></asp:Label>
                                        </ItemTemplate>                                     
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="Address" SortExpression="address">
                                        <ItemTemplate>
                                            <asp:Label ID="lbladd" runat="server" Text='<%# Eval("address") %>'></asp:Label>
                                        </ItemTemplate>                                        
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="Phone" SortExpression="pre_mob">
                                        <ItemTemplate>
                                            <asp:Label ID="lblmob" runat="server" Text='<%# Eval("pre_mob") %>'></asp:Label>
                                        </ItemTemplate>                                
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="House No." SortExpression="house_no">
                                        <ItemTemplate>
                                            <asp:Label ID="lblHouseNo" runat="server" Text='<%# Eval("house_no") %>'></asp:Label>
                                        </ItemTemplate>                                     
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="House SqFt" SortExpression="area">
                                        <ItemTemplate>
                                            <asp:Label ID="lblHouseSqft" runat="server" Text='<%# Eval("area") %>'></asp:Label>
                                        </ItemTemplate>
                                        <EditItemTemplate>
                                            <asp:TextBox ID="txtHouseSqft" runat="server" Text='<%# Bind("area") %>'></asp:TextBox>
                                        </EditItemTemplate>
                                    </asp:TemplateField>

                                    <asp:TemplateField HeaderText="SqFt Charges (₹)" SortExpression="gharpatti_charges">
                                        <ItemTemplate>
                                            <asp:Label ID="lblSqftCharges" runat="server" Text='<%# Eval("gharpatti_charges", "{0:F2}") %>'></asp:Label>
                                        </ItemTemplate>
                                        <EditItemTemplate>
                                            <asp:TextBox ID="txtSqftCharges" runat="server" Text='<%# Bind("gharpatti_charges") %>'></asp:TextBox>
                                        </EditItemTemplate>
                                    </asp:TemplateField>

                                    <asp:TemplateField HeaderText="No. of Taps" SortExpression="no_of_tab">
                                        <ItemTemplate>
                                            <asp:Label ID="lblNoOfTaps" runat="server" Text='<%# Eval("no_of_tab") %>'></asp:Label>
                                        </ItemTemplate>
                                        <EditItemTemplate>
                                            <asp:TextBox ID="txtNoOfTaps" runat="server" Text='<%# Bind("no_of_tab") %>'></asp:TextBox>
                                        </EditItemTemplate>
                                    </asp:TemplateField>

                                    <asp:TemplateField HeaderText="Tap Charges (₹)" SortExpression="water_charges">
                                        <ItemTemplate>
                                            <asp:Label ID="lblTapCharges" runat="server" Text='<%# Eval("water_charges", "{0:F2}") %>'></asp:Label>
                                        </ItemTemplate>
                                        <EditItemTemplate>
                                            <asp:TextBox ID="txtTapCharges" runat="server" Text='<%# Bind("water_charges") %>'></asp:TextBox>
                                        </EditItemTemplate>
                                    </asp:TemplateField>

                                    <asp:TemplateField HeaderText="Waste Collection(₹)" SortExpression="waste_charges">
                                        <ItemTemplate>
                                            <asp:Label ID="lblSolidWasteFee" runat="server" Text='<%# Eval("waste_charges", "{0:F2}") %>'></asp:Label>
                                        </ItemTemplate>
                                        <EditItemTemplate>
                                            <asp:TextBox ID="txtSolidWasteFee" runat="server" Text='<%# Bind("waste_charges") %>'></asp:TextBox>
                                        </EditItemTemplate>
                                    </asp:TemplateField>
                                    <%--            
                        <asp:BoundField DataField="TotalAmount" HeaderText="Total Amount (₹)" 
                            DataFormatString="{0:F2}" ReadOnly="True" ItemStyle-CssClass="total-amount" />--%>

                                    <asp:TemplateField HeaderText="Actions">
                                        <ItemTemplate>
                                            <asp:Button ID="btnEdit" runat="server" Text="Edit"
                                                CommandName="Edit" CssClass="btn-edit" />
                                        </ItemTemplate>
                                        <EditItemTemplate>
                                            <asp:Button ID="btnUpdate" runat="server" Text="Update"
                                                CommandName="Update" CssClass="btn-update" />
                                            <asp:Button ID="btnCancel" runat="server" Text="Cancel"
                                                CommandName="Cancel" CssClass="btn-cancel" />
                                        </EditItemTemplate>
                                    </asp:TemplateField>
                                </Columns>
                            </asp:GridView>
                        </div>

<%--            <asp:Button ID="btnSaveAll" runat="server" Text="Save All Changes"
                            CssClass="btn-save-all" OnClick="btnSaveAll_Click" />--%>

                        <asp:Label ID="lblMessage" runat="server" ForeColor="Green"
                            Style="margin-left: 20px; font-weight: bold;"></asp:Label>
                    </div>


                    <%--import modal--%>
                    <div class="modal fade bs-example-modal-sm" id="import_model" tabindex="-1" role="dialog" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                        <div class="modal-dialog modal-sm-1">
                            <iv class="modal-content resized-model">
                                <div class="modal-body">
                                    <div class="form-group">
                                        <div class="row">
                                            <div class="col-sm-4">
                                                <asp:Label ID="Label27" runat="server" Text="Type of Data"></asp:Label>
                                                <asp:Label ID="Label33" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>

                                            </div>
                                            <div class="col-sm-4">

                                                <asp:DropDownList ID="ddl_import" runat="server" Width="200px" Height="32px">
                                                    <asp:ListItem Value="building">Building</asp:ListItem>
                                                    <asp:ListItem Value="owner">Owner</asp:ListItem>
                                                    <asp:ListItem Value="society_member">Society Member</asp:ListItem>
                                                </asp:DropDownList>

                                            </div>
                                        </div>
                                    </div>
                                    <div class="form-group">
                                        <div class="row">
                                            <div class="col-sm-4">
                                                <asp:Label ID="Label75" runat="server" Text="Upload File"></asp:Label>
                                                <asp:Label ID="Label76" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>

                                            </div>
                                            <div class="col-sm-4">
                                                <asp:FileUpload ID="houseXL" runat="server" accept=".xls,.xlsx,.csv" />
                                                <asp:Label ID="uploadedfiles" runat="server" ForeColor="Green" />
                                            </div>


                                        </div>

                                    </div>
                                </div>

                                <div class="modal-footer">


                                    <div class="form-group">
                                        <div class="row ">
                                            <center>
                                                <asp:Button ID="btn_photo_upload" runat="server" Text="Import" Class="btn btn-primary" UseSubmitBehavior="false" OnClick="btn_house_upload_Click" />
                                                <asp:Button ID="Button1" runat="server" Text="Close" class="btn btn-primary" UseSubmitBehavior="False" OnClientClick="resetForm(); return false;" data-dismiss="modal" />

                                            </center>
                                        </div>
                                    </div>


                                </div>
                        </div>
                    </div>


                    <!-- Add New House Modal -->
<div class="modal fade" id="addHouseModal" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content">
            
            <div class="modal-header">
                <h5 class="modal-title">Add House Details</h5>
                <button type="button" class="close" data-dismiss="modal">
                    <span>&times;</span>
                </button>
            </div>

            <div class="modal-body">
                <asp:UpdatePanel runat="server">
                    <ContentTemplate>

                        <div class="form-group">
                            <label>Owner Name</label>
                            <asp:TextBox ID="txtOwnerName" CssClass="form-control" runat="server"></asp:TextBox>
                        </div>

                        <div class="form-group">
                            <label>Address</label>
                            <asp:TextBox ID="txtAddress" CssClass="form-control" runat="server"></asp:TextBox>
                        </div>

                        <div class="form-group">
                            <label>Phone</label>
                            <asp:TextBox ID="txtPhone" CssClass="form-control" runat="server"></asp:TextBox>
                        </div>

                        <div class="form-row">
                            <div class="form-group col-md-6">
                                <label>House No.</label>
                                <asp:TextBox ID="txtHouseNo" CssClass="form-control" runat="server"></asp:TextBox>
                            </div>

                            <div class="form-group col-md-6">
                                <label>House SqFt</label>
                                <asp:TextBox ID="txtSqft" CssClass="form-control" runat="server"></asp:TextBox>
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="form-group col-md-4">
                                <label>SqFt Charges (₹)</label>
                                <asp:TextBox ID="txtSqftCharges" CssClass="form-control" runat="server"></asp:TextBox>
                            </div>

                            <div class="form-group col-md-4">
                                <label>No. of Taps</label>
                                <asp:TextBox ID="txtTaps" CssClass="form-control" runat="server"></asp:TextBox>
                            </div>

                            <div class="form-group col-md-4">
                                <label>Tap Charges (₹)</label>
                                <asp:TextBox ID="txtTapCharges" CssClass="form-control" runat="server"></asp:TextBox>
                            </div>
                        </div>

                        <div class="form-group">
                            <label>Waste Collection (₹)</label>
                            <asp:TextBox ID="txtWaste" CssClass="form-control" runat="server"></asp:TextBox>
                        </div>

                    </ContentTemplate>
                </asp:UpdatePanel>
            </div>

            <div class="modal-footer">
                <asp:Button ID="btnSubmitHouse" runat="server" Text="Submit" CssClass="btn btn-primary" OnClick="btnSubmitHouse_Click" />
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
            </div>

        </div>
    </div>
</div>

                </div>
            </div>
        </div>

         <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

 <script type="text/javascript">
     function FailedEntryy() {
         Swal.fire({
             title: '❌ Rejected!',
             text: '',
             icon: 'error',
             showConfirmButton: true,
             confirmButtonColor: '#d33',
             confirmButtonText: 'Retry',
             timer: 1500,
             branding: false,
             timerProgressBar: true,
             didOpen: () => {
                 Swal.showLoading()
             }
         });
     }

     function SuccessEntryy() {
         Swal.fire({
             title: '✅ Approved!',
             text: '',
             icon: 'success',
             showConfirmButton: true,
             confirmButtonColor: '#3085d6',
             confirmButtonText: 'OK',
             timer: 1500,
             branding: false,
             timerProgressBar: true,
             didOpen: () => {
                 Swal.showLoading()
             },
             willClose: () => {
                 window.location = 'v_resident.aspx'
}
         });
     }

     function filterTable() {
         const input = document.getElementById('<%= txt_search.ClientID %>');
         if (!input) return;

         const filter = input.value.toLowerCase();
         const table = document.querySelector('.grid-wrapper table');

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

 </script>
    </body> 
</asp:Content>
