<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="owner_search.aspx.cs" Inherits="Society.owner_search" MasterPageFile="~/Site.Master" MaintainScrollPositionOnPostback="True" %>
<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0&icon_names=search" />
    <style>
        .resized-model {
            width: 100%;
            max-width: 900px;
            height: auto;
            margin: auto;
        }
        .suggestion-list {
            position: absolute;
            z-index: 1000;
            background: white;
            border: 1px solid #ccc;
            max-height: 200px;
            overflow-y: auto;
            width: 100%;
            /*display: none;*/ /* hidden by default */
            /*position: absolute;*/ /* sits over other elements */
            /*z-index: 1050;*/ /* above modal backdrop */
            /*background: #fff;
            border: 1px solid #ccc;
            width: 100%;*/ /* match textbox width */
            /*max-height: 200px;*/ /* scrollable if many items */
            /*overflow-y: auto;
        }*/
        }
        .suggestion-item {
            padding: 8px;
            cursor: pointer;
        }
        .suggestion-item:hover {
            background: #f0f0f0;
        }
        .overflow-div {
            width: 100%;
            max-width: 200px;
            height: 25px;
            word-wrap: break-word;
            overflow: hidden;
            white-space: nowrap;
            text-overflow: ellipsis;
        }
        @media print {
            .no-print {
                display: none !important;
            }
        }
        @media (max-width: 576px) {
            .resized-model {
                max-width: 100%;
                margin: 0.5rem;
            }
            .modal-dialog {
                margin: 0.5rem;
            }
            .search-container {
                width: 100%;
            }
            .input-buttons {
                display: flex;
                justify-content: flex-end;
            }
            .suggestion-list {
                width: 100% !important;
            }
            .form-control {
                width: 100% !important;
            }
            .btn {
                /*width: 100%;*/
                margin-top: 0.5rem;
            }
            .overflow-div {
                max-width: 100%;
            }
        }



             /* File Upload Styling */
     input[type="file"] {
         padding: 10px;
         border: 2px dashed #e0e0e0;
         border-radius: 8px;
         background: #fafafa;
         cursor: pointer;
         transition: all 0.3s ease;
         font-size: 14px;
         width: 100%;
     }

         input[type="file"]:hover {
             border-color: #667eea;
             background: #f5f7ff;
         }

         input[type="file"]::-webkit-file-upload-button {
             padding: 8px 16px;
             background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
             color: white;
             border: none;
             border-radius: 6px;
             cursor: pointer;
             font-size: 13px;
             font-weight: 500;
             margin-right: 10px;
             transition: all 0.2s ease;
         }

             input[type="file"]::-webkit-file-upload-button:hover {
                 transform: translateY(-1px);
                 box-shadow: 0 2px 8px rgba(102, 126, 234, 0.3);
             }

         /* Firefox */
         input[type="file"]::file-selector-button {
             padding: 8px 16px;
             background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
             color: white;
             border: none;
             border-radius: 6px;
             cursor: pointer;
             font-size: 13px;
             font-weight: 500;
             margin-right: 10px;
             transition: all 0.2s ease;
         }

             input[type="file"]::file-selector-button:hover {
                 transform: translateY(-1px);
                 box-shadow: 0 2px 8px rgba(102, 126, 234, 0.3);
             }

             #pdf-clone-container table {
    border-collapse: collapse !important;
    border: 2px solid #000 !important;
}

#pdf-clone-container td,
#pdf-clone-container th {
    border: 1.5px solid #000 !important;
}
    </style>

    <div class="box box-primary">
        <div class="box-header with-border">
            <div class="box-body">
                <table class="w-100">
                    <tr>
                        <th>
                            <h1 class="font-weight-bold" style="color: #012970;">Flat Owners</h1>
                        </th>
                    </tr>
                </table>
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <div class="form-group">
                            <div class="row">
                                <div class="col-12">
                                    <div class="d-flex align-items-center flex-wrap">
                                        <div class="search-container ">
                                            <asp:TextBox
                                                ID="txt_search"
                                                CssClass="aspNetTextBox form-control"
                                                placeHolder="Search here"
                                                runat="server"
                                                TextMode="Search"
                                                 autocomplete="off"
                                                onkeyup="filterTable()"/>
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
                                        <button type="button" class="btn btn-primary mt-2 mt-sm-0" data-toggle="modal" data-target="#edit_model">Add</button>
                                        &nbsp;&nbsp;
                                        <button type="button" class="btn btn-primary mt-2 mt-sm-0" onclick="printFlatMaster()">Print</button>
                                        &nbsp;&nbsp;
                                        <button type="button" class="btn btn-success mt-2 mt-sm-0" onclick="downloadReceipt()">Download PDF</button>
                                        &nbsp;&nbsp;
                                        <button type="button" class="btn btn-success mt-2 mt-sm-0" onclick="exportSelectedColumnsToExcel('<%= OwnerGrid.ClientID %>', [0,1,3])">Export to Excel</button>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="form-group">
                            <div class="row">
                                <div class="col-12">
                                    <div class="table-responsive table-container">
                                        <asp:GridView ID="OwnerGrid" runat="server" AllowPaging="true" PageSize="100" OnPageIndexChanging="OwnerGrid_PageIndexChanging" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" HeaderStyle-BackColor="lightblue" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" OnRowUpdating="OwnerGrid_RowUpdating" OnSorting="OwnerGrid_Sorting" OnRowDeleting="OwnerGrid_RowDeleting">
                                            <Columns>
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="owner_id" SortExpression="owner_id" Visible="false">
                                                    <ItemTemplate>
                                                        <asp:Label runat="server" ID="owner_id" Text='<%# Bind("owner_id")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Name" SortExpression="name" ItemStyle-Width="100">
                                                    <ItemTemplate>
                                                        <asp:Label runat="server" ID="name" Text='<%# Bind("name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <%--<asp:TemplateField HeaderText="Building" SortExpression="build_name" ItemStyle-Width="150">
                                                    <ItemTemplate>
                                                        <asp:Label ID="addr2" runat="server" Text='<%# Bind("build_name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>--%>
                                                <asp:TemplateField HeaderText="Unit" SortExpression="unit" ItemStyle-Width="100">
                                                    <ItemTemplate>
                                                        <asp:Label ID="addr1" runat="server" Text='<%# Bind("unit")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Type" SortExpression="flat_type" ItemStyle-Width="100">
                                                    <ItemTemplate>
                                                        <asp:Label ID="addr" runat="server" Text='<%# Bind("flat_details")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Edit" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit" OnCommand="edit_Command" CommandName="Update" CommandArgument='<%# Bind("owner_id")%>' OnClientClick="openModal();"><img src="Images/123.png"/></asp:LinkButton>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Delete" Visible="false" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit551" CommandName="Delete" OnClientClick="return confirm('Are you sure want to delete?');"><img src="Images/delete_10781634.png" height="25" width="25" /></asp:LinkButton>
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
                <div class="modal fade" id="edit_model" role="form" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                    <div class="modal-dialog modal-lg">
                        <div class="modal-content resized-model">
                            <div class="modal-header">
                                <h4 class="modal-title"><strong>Owner Details</strong></h4> 
                            </div>
                            <div class="modal-body" id="invoice_data">
                                <asp:UpdatePanel ID="modalpanel" runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>
                                        <asp:HiddenField ID="owner_id" runat="server" />
                                        <asp:HiddenField ID="o_ex_id" runat="server"></asp:HiddenField>
                                        <asp:HiddenField ID="society_id" runat="Server"></asp:HiddenField>
                                        <asp:HiddenField ID="flat_id" runat="server" />
                                        <asp:HiddenField ID="flat_no_id" runat="server" />
                                        <asp:HiddenField ID="Buildling_wing_id" runat="server" />
                                        <asp:HiddenField ID="type_id" runat="server" />
                                        <asp:HiddenField ID="married_id" runat="server" />
                                        <asp:HiddenField ID="doc_id_id" runat="server" />
                                        <asp:HiddenField ID="society_name" runat="server" />
                                        <div class="form-group">
                                            <div class="row align-items-center mb-3">
                                                <div class="col-12 col-sm-3">
                                                    <asp:Label ID="lbl_acc_no" runat="server" Text="Building & Wing"></asp:Label>
                                                    <asp:Label ID="lbl_acc_no_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox1" runat="server" CssClass="input-box form-control" placeholder="Select" autocomplete="off" required="required" />
                                                        <div id="RepeaterContainer1" class="suggestion-list">
                                                            <asp:Repeater ID="Repeater1" runat="server" OnItemCommand="CategoryRepeater_ItemCommand1" OnItemDataBound="Repeater1_ItemDataBound">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='<%# Eval("name") %>'
                                                                        CommandArgument='<%# Eval("wing_id") %>'
                                                                        CommandName="SelectCategory"
                                                                        OnClientClick="setTextBox1(this.innerText);" />
                                                                </ItemTemplate>
                                                                <FooterTemplate>
                                                                    <asp:Literal ID="litNoItem" runat="server" Visible='<%# ((Repeater)Container.NamingContainer).Items.Count == 0 %>'
                                                                        Text="No items found." />
                                                                </FooterTemplate>
                                                            </asp:Repeater>
                                                        </div>
                                                    </div>
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <asp:Label ID="lbl_date" runat="server" Text="Poss Date"></asp:Label>
                                                    <asp:Label ID="lbl_date_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <asp:TextBox ID="txt_poss_date" CssClass="form-control" runat="server" TextMode="Date" required></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Select Date
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <div class="row align-items-center mb-3">
                                                <div class="col-12 col-sm-3">
                                                    <asp:Label ID="Label5" runat="server" Text="Type"></asp:Label>
                                                    <asp:Label ID="Label7" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox2" runat="server" CssClass="input-box form-control" placeholder="Select" autocomplete="off" required="required" />
                                                        <div id="RepeaterContainer2" class="suggestion-list">
                                                            <asp:Repeater ID="Repeater2" runat="server" OnItemCommand="CategoryRepeater_ItemCommand2" OnItemDataBound="Repeater2_ItemDataBound">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='<%# Eval("flat_type") %>'
                                                                        CommandArgument='<%# Eval("flat_type_id") %>'
                                                                        CommandName="SelectCategory"
                                                                        OnClientClick="setTextBox2(this.innerText);" />
                                                                </ItemTemplate>
                                                                <FooterTemplate>
                                                                    <asp:Literal ID="litNoItem" runat="server" Visible='<%# ((Repeater)Container.NamingContainer).Items.Count == 0 %>'
                                                                        Text="No items found." />
                                                                </FooterTemplate>
                                                            </asp:Repeater>
                                                        </div>
                                                    </div>
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <asp:Label ID="Label8" runat="server" Text="Flat No"></asp:Label>
                                                    <asp:Label ID="Label10" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox3" runat="server" CssClass="input-box form-control" placeholder="Select" autocomplete="off" required="required" />
                                                        <div id="RepeaterContainer3" class="suggestion-list">
                                                            <asp:Repeater ID="Repeater3" runat="server" OnItemCommand="CategoryRepeater_ItemCommand3" OnItemDataBound="Repeater3_ItemDataBound">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='<%# Eval("flat_type") %>'
                                                                        CommandArgument='<%# Eval("flat_id") %>'
                                                                        CommandName="SelectCategory"
                                                                        OnClientClick="setTextBox3(this.innerText);" />
                                                                </ItemTemplate>
                                                                <FooterTemplate>
                                                                    <asp:Literal ID="litNoItem" runat="server" Visible='<%# ((Repeater)Container.NamingContainer).Items.Count == 0 %>'
                                                                        Text="No items found." />
                                                                </FooterTemplate>
                                                            </asp:Repeater>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <div class="row align-items-center mb-3">
                                                <div class="col-12 col-sm-3">
                                                    <asp:Label ID="lbl_name" runat="server" Text="Name"></asp:Label>
                                                    <asp:Label ID="lbl_name_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <asp:TextBox ID="txt_name" CssClass="form-control" runat="server" Style="text-transform: capitalize;" MaxLength="50" placeholder="Enter Name" required></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Name
                                                    </div>
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <asp:Label ID="lbl_mob" runat="server" Text="E-mail ID"></asp:Label>
                                                    <asp:Label ID="Label12" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <asp:TextBox ID="txt_email" CssClass="form-control" TextMode="Email" placeholder="Enter Email" required runat="server"></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Valid Email ID
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <div class="row align-items-center mb-3">
                                                <div class="col-12 col-sm-3">
                                                    <asp:Label ID="lbl_pre_mob" runat="server" Text="Mobile No."></asp:Label>
                                                    <asp:Label ID="lbl_pre_mob_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <asp:TextBox ID="txt_pre_mob" onkeypress="return event.charCode >= 48 && event.charCode <= 57" CssClass="form-control" runat="server" MaxLength="10" TextMode="Phone" placeholder="Enter Mobile No." AutoPostBack="true" required></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Mobile No
                                                    </div>
                                                    <asp:Label ID="Label16" runat="server" Font-Bold="True" ForeColor="Red"></asp:Label>
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <asp:Label ID="lbl_add_mob" runat="server" Text="Alternate Mobile No."></asp:Label>
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <asp:TextBox ID="txt_add_mob" CssClass="form-control not-required" runat="server" MaxLength="10" placeholder="Enter Alternate Mobile No."></asp:TextBox>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <div class="row align-items-center mb-3">
                                                <div class="col-12 col-sm-3">
                                                    <asp:Label ID="lbl_married" runat="server" Text="Married"></asp:Label>
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox4" runat="server" CssClass="input-box form-control" placeholder="Select" autocomplete="off" required="required" />
                                                        <div id="RepeaterContainer4" class="suggestion-list">
                                                            <asp:Repeater ID="Repeater4" runat="server" OnItemDataBound="Repeater4_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand4">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='<%# Eval("married_name") %>'
                                                                        CommandArgument='<%# Eval("married_id") %>'
                                                                        CommandName="SelectCategory"
                                                                        OnClientClick="setTextBox4(this.innerText);" />
                                                                </ItemTemplate>
                                                                <FooterTemplate>
                                                                    <asp:Literal ID="litNoItem" runat="server" Visible='<%# ((Repeater)Container.NamingContainer).Items.Count == 0 %>'
                                                                        Text="No items found." />
                                                                </FooterTemplate>
                                                            </asp:Repeater>
                                                        </div>
                                                    </div>
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <asp:Label ID="Label27" runat="server" Text="DOB"></asp:Label>
                                                 
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <asp:TextBox ID="txt_dob" CssClass="form-control" runat="server" TextMode="Date"></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Select Date
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    <!-- File Upload -->
                                    <div class="form-group">
                                        <div class="row align-items-center mb-3">
                                            <div class="col-12 col-sm-3">
                                                <asp:Label ID="Label1" runat="server" Text="ID Proof"></asp:Label>
                                                <asp:Label ID="Label2" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                            </div>
                                            <div class="col-12 col-sm-9">
                                                <asp:FileUpload ID="FileUpload1" runat="server" accept=".pdf, .jpg, .jpge" onchange="validateFileSize(this)"/>
                                                <div class="overflow-div">
                                                    <asp:Label ID="listofuploadedfiles" runat="server" />
                                                </div>
                                                <asp:Label ID="uploadphotopath" runat="server" Visible="false" />
                                            </div>
                                        </div>
                                    </div>
<%--                                        <div class="form-group">
                                            <div class="row align-items-center mb-3">
                                                <div class="col-12 col-sm-3">
                                                    <asp:Label ID="Label1" runat="server" Text="Photo Proof"></asp:Label>
                                                    <asp:Label ID="Label11" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-12 col-sm-9">
                                                    <asp:FileUpload ID="FileUpload1" runat="server" accept=".jpg,.jpeg" />
                                                    <asp:Button ID="btn_photo_upload" runat="server" Text="Upload" Class="btn btn-primary mt-2 mt-sm-0" OnClick="btn_photo_upload_Click" UseSubmitBehavior="False" />
                                                    <div class="overflow-div">
                                                        <asp:Label ID="listofuploadedfiles" runat="server" />
                                                    </div>
                                                    <asp:Label ID="uploadphotopath" runat="server" Visible="false" />
                                                </div>
                                            </div>
                                        </div>--%>
                                        <hr />
                                        <div class="box-header">
                                            <div class="row">
                                                <div class="col-12">
                                                    <h3 class="box-title"><b>Occupation Details</b></h3>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <div class="row align-items-center mb-3">
                                                <div class="col-12 col-sm-3">
                                                    <asp:Label ID="lbl_occup" runat="server" Text="Occupation"></asp:Label>
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <asp:TextBox ID="txt_occup" CssClass="form-control not-required" runat="server" Style="text-transform: capitalize;" MaxLength="250" placeholder="Enter Occupation"></asp:TextBox>
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <asp:Label ID="lbl_mon_inc" runat="server" Text="Monthly Income"></asp:Label>
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <asp:TextBox CssClass="form-control not-required" ID="txt_monthly_income" runat="server" Style="text-transform: capitalize;" MaxLength="50" placeholder="Enter Monthly Income"></asp:TextBox>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <div class="row align-items-center mb-3">
                                                <div class="col-12 col-sm-3">
                                                    <asp:Label ID="lbl_off_addr1" runat="server" Text="Office Address"></asp:Label>
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <asp:TextBox ID="txt_off_addr1" CssClass="form-control not-required" runat="server" Style="text-transform: capitalize;" MaxLength="250" placeholder="Enter Office Address"></asp:TextBox>
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <asp:Label ID="lbl_off_tel" runat="server" Text="Office Tel."></asp:Label>
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <asp:TextBox CssClass="form-control not-required" ID="txt_off_tel" runat="server" MaxLength="10" onkeypress="return digit(event);" placeholder="Enter Office Tel."></asp:TextBox>
                                                    <asp:RegularExpressionValidator ID="RegularExpressionValidator3" runat="server" ControlToValidate="txt_off_tel" ErrorMessage="Numbers Only" Font-Bold="True" ForeColor="Red" ValidationExpression="^\d+" Display="Dynamic" ValidationGroup="g1"></asp:RegularExpressionValidator>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="box-header">
                                            <div class="row">
                                                <div class="col-12">
                                                    <h3 class="box-title"><b>Family Members Name</b></h3>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <div class="row align-items-center mb-3">
                                                <div class="col-12 col-sm-3">
                                                    <asp:Label ID="lbl_tof_acc" runat="server" Text="Family Member"></asp:Label>
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <asp:TextBox CssClass="form-control not-required" ID="txt_fam_mem_name" Style="text-transform: capitalize;" runat="server" placeholder="Enter Name "></asp:TextBox>
                                                    <asp:Label ID="Label17" runat="server" Font-Bold="True" ForeColor="Red" Font-Size="Medium"></asp:Label>
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <asp:Label ID="lbl_bank_acc" runat="server" Text="Relation"></asp:Label>
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <asp:TextBox CssClass="form-control not-required" ID="txt_owner_rel" runat="server" Style="text-transform: capitalize;" MaxLength="50" placeholder="Enter Relation"></asp:TextBox>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <div class="row align-items-center mb-3">
                                                <div class="col-12 col-sm-3">
                                                    <asp:Label ID="lbl_bank" runat="server" Text="Occupation"></asp:Label>
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <asp:TextBox CssClass="form-control not-required" ID="txt_f_occu" runat="server" Style="text-transform: capitalize;" MaxLength="50" placeholder="Enter Occupation"></asp:TextBox>
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <asp:Label ID="lbl_bank_addr1" runat="server" Text="DOB"></asp:Label>
                                                </div>
                                                <div class="col-12 col-sm-3">
                                                    <asp:TextBox CssClass="form-control not-required" ID="txt_f_dob" runat="server" MaxLength="50" placeholder="Enter Dob" TextMode="Date"></asp:TextBox>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <div class="row">
                                                <div class="col-12 text-center">
                                                    <asp:Button ID="add" class="btn btn-primary" runat="server" Text="Add" OnClick="btn_add_Click" />
                                                </div>
                                            </div>
                                        </div>
                                        <hr />
                                        <div class="form-group">
                                            <div class="row">
                                                <div class="col-12">
                                                    <div class="table-responsive">
                                                        <asp:GridView ID="FamilyGrid" runat="server" CssClass="table table-bordered table-hover table-striped" AutoGenerateColumns="false" OnRowUpdating="FamilyGrid_RowUpdating" OnRowDeleting="FamilyGrid_RowDeleting" OnSorting="FamilyGrid_Sorting" AllowSorting="True" HeaderStyle-BackColor="lightblue" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found">
                                                            <Columns>
                                                                <asp:TemplateField HeaderText="detail_id" Visible="false">
                                                                    <ItemTemplate>
                                                                        <asp:Label ID="o_ex_id" runat="server" Text='<%# Bind("o_ex_id")%>'></asp:Label>
                                                                    </ItemTemplate>
                                                                </asp:TemplateField>
                                                                <asp:TemplateField HeaderText="owner_id" Visible="false">
                                                                    <ItemTemplate>
                                                                        <asp:Label ID="owner_id" runat="server" Text='<%# Bind("owner_id")%>'></asp:Label>
                                                                    </ItemTemplate>
                                                                </asp:TemplateField>
                                                                <asp:TemplateField HeaderText="Name" SortExpression="f_name" ItemStyle-Width="150">
                                                                    <ItemTemplate>
                                                                        <asp:Label ID="f_name" runat="server" Text='<%# Bind("f_name")%>'></asp:Label>
                                                                    </ItemTemplate>
                                                                </asp:TemplateField>
                                                                <asp:TemplateField HeaderText="Relation" SortExpression="relation" ItemStyle-Width="100">
                                                                    <ItemTemplate>
                                                                        <asp:Label ID="relation" runat="server" Text='<%# Bind("relation")%>'></asp:Label>
                                                                    </ItemTemplate>
                                                                </asp:TemplateField>
                                                                <asp:TemplateField HeaderText="Occupation" SortExpression="f_occu" ItemStyle-Width="150">
                                                                    <ItemTemplate>
                                                                        <asp:Label ID="f_occu" runat="server" Text='<%# Bind("f_occu")%>'></asp:Label>
                                                                    </ItemTemplate>
                                                                </asp:TemplateField>
                                                                <asp:TemplateField HeaderText="DOB" SortExpression="f_dob" ItemStyle-Width="100">
                                                                    <ItemTemplate>
                                                                        <asp:Label ID="f_dob" runat="server" Text='<%# Bind("f_dob", "{0:dd-MM-yyyy}")%>'></asp:Label>
                                                                    </ItemTemplate>
                                                                </asp:TemplateField>
                                                                <asp:TemplateField ItemStyle-Width="50">
                                                                    <ItemTemplate>
                                                                        <asp:LinkButton runat="server" ID="edit551" CommandName="Delete" OnClientClick="return confirm('Are you sure want to delete?');"><img src="Images/delete_10781634.png" height="25" width="25" /></asp:LinkButton>
                                                                    </ItemTemplate>
                                                                </asp:TemplateField>
                                                            </Columns>
                                                        </asp:GridView>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <asp:Label runat="server" ID="lbl_Building" Visible="false"></asp:Label>
                                    </ContentTemplate>
                                    <Triggers>
                                        <asp:AsyncPostBackTrigger ControlID="OwnerGrid" EventName="RowCommand" />                                        
                                        <%--<asp:PostBackTrigger ControlID="btn_photo_upload" />--%>
                                        <%--<asp:PostBackTrigger ControlID="btnotice_id_upload" />--%>
                                        <%--<asp:PostBackTrigger ControlID="add" />--%>
                                    </Triggers>
                                </asp:UpdatePanel>
                            </div>
                            <div class="modal-footer">
                                <div class="row">
                                    <div class="col-12 text-center">
                                        <asp:Button ID="btn_save" OnClientClick="disableSaveButtonIfValid();" runat="server" Text="Save" OnClick="btn_save_Click1" ValidationGroup="g1" class="btn btn-primary mr-2" />
                                        <asp:Button ID="btn_delete" class="btn btn-primary mr-2" Visible="false" runat="server" Text="Delete" OnClientClick="return confirm('Are you sure want to delete?');" OnClick="btn_delete_Click" />
                                        <asp:Button ID="btn_close" runat="server" Text="Close" class="btn btn-primary" UseSubmitBehavior="False" OnClientClick="resetForm(); return false;" data-dismiss="modal" />
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="modal fade" id="exportModal" tabindex="-1" role="dialog" aria-labelledby="exportModalLabel" aria-hidden="true">
                    <div class="modal-dialog modal-lg">
                        <div class="modal-content resized-model">
                            <div class="modal-header bg-primary text-white">
                                <h5 class="modal-title" id="exportModalLabel">Export Owner Data</h5>
                                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                    <span aria-hidden="true">&times;</span>
                                </button>
                            </div>
                            <div class="modal-body">
                                <div class="table-responsive">
                                    <asp:GridView ID="ExportGrid" runat="server" CssClass="table table-bordered table-striped" AutoGenerateColumns="true" />
                                </div>
                            </div>
                            <div class="modal-footer">
                                <asp:Button ID="Button1" runat="server" Text="Export to Excel" CssClass="btn btn-success" OnClick="btnExportToExcel_Click" />
                                <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="modal fade" id="pdfmodal" role="form" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                    <div class="modal-dialog modal-lg">
                        <div class="modal-content resized-model">
                            <div class="modal-header" style="justify-content: center;">
                                <h4 class="modal-title text-center"><strong>Owner Details</strong></h4>
                            </div>
                            <div class="modal-body">
                                <div style="text-align: center; margin-bottom: 10px;">
                                    <h4><strong><%= society_name.Value %></strong></h4>
                                </div>
                                <div class="table-responsive" style="padding: 10px; border-radius: 5px; background-color: #f9f9f9;">
                                    <asp:GridView ID="GridView2" runat="server"
                                        CssClass="table table-bordered table-hover table-sm gridview-custom"
                                        AutoGenerateColumns="false"
                                        ShowHeaderWhenEmpty="true"
                                        EmptyDataText="No data found."
                                        HeaderStyle-BackColor="#012970"
                                        HeaderStyle-ForeColor="White"
                                        Font-Size="Small"
                                        GridLines="Both"
                                        CellPadding="6"
                                        BorderStyle="None"
                                        BorderWidth="0px">
                                        <Columns>
                                            <asp:TemplateField HeaderText="No" ItemStyle-Width="50">
                                                <ItemTemplate>
                                                    <asp:Label ID="lblRowNumber" runat="server" Text='<%# Container.DataItemIndex + 1 %>' />
                                                </ItemTemplate>
                                            </asp:TemplateField>
                                            <asp:BoundField HeaderText="Owner ID" DataField="owner_id" SortExpression="owner_id" ItemStyle-Width="100" />
                                            <asp:BoundField HeaderText="Name" DataField="name" SortExpression="name" ItemStyle-Width="150" />
                                            <asp:BoundField HeaderText="Building" DataField="build_name" SortExpression="build_name" ItemStyle-Width="150" />
                                            <asp:BoundField HeaderText="Unit" DataField="unit" SortExpression="unit" ItemStyle-Width="100" />
                                            <asp:BoundField HeaderText="Type" DataField="flat_type" SortExpression="flat_type" ItemStyle-Width="100" />
                                        </Columns>
                                    </asp:GridView>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div id="pdf-clone-container" style="position: absolute; top: -10000px; left: -10000px;"></div>
            </div>
        </div>
    </div>



    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>
    <script src="https://html2canvas.hertzen.com/dist/html2canvas.min.js"></script>
    <script src="vendor/jquery/jquery.min.js"></script>
    <script src="vendor/bootstrap/js/bootstrap.bundle.min.js"></script>
    <script src="vendor/jquery-easing/jquery.easing.min.js"></script>
    <script type="text/javascript">
        function FailedEntry() {
            Swal.fire({
                title: '❌ Failed!',
                text: 'Something went wrong. Please try again.',
                icon: 'error',
                showConfirmButton: true,
                confirmButtonColor: '#d33',
                confirmButtonText: 'Retry',
                timer: 3000,
                timerProgressBar: true,
                didOpen: () => {
                    Swal.showLoading()
                }
            });
        }


        function SuccessEntry() {
            Swal.fire({
                title: '✅ Success!',
                text: 'Saved Successfully',
                icon: 'success',
                showConfirmButton: true,
                confirmButtonColor: '#3085d6',
                confirmButtonText: 'OK',
                timer: 1400,
                timerProgressBar: true,
                didOpen: () => {
                    Swal.showLoading()
                },
                willClose: () => {
                    window.location.href = 'owner_search.aspx';
                }
            });
        }


        function disableSaveButtonIfValid() {
            var btn = document.getElementById('<%= btn_save.ClientID %>');
            var modal = document.getElementById('edit_model');
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
                __doPostBack('<%= btn_save.UniqueID %>', '');
                return false;
            }
            return false;
        }


        function openModal() {
            $('#edit_model').modal('show');
        }


        function closeAllDropdowns() {
            document.getElementById("RepeaterContainer1").style.display = "none";
            document.getElementById("RepeaterContainer2").style.display = "none";
            document.getElementById("RepeaterContainer3").style.display = "none";
            document.getElementById("RepeaterContainer4").style.display = "none";
        }
       

        function initDropdownEvents() {

            const textBox1 = document.getElementById("<%= TextBox1.ClientID %>");
            const textBox2 = document.getElementById("<%= TextBox2.ClientID %>");
            const textBox3 = document.getElementById("<%= TextBox3.ClientID %>");
            const textBox4 = document.getElementById("<%= TextBox4.ClientID %>");

            const repeaterContainer1 = document.getElementById("RepeaterContainer1");
            const repeaterContainer2 = document.getElementById("RepeaterContainer2");
            const repeaterContainer3 = document.getElementById("RepeaterContainer3");
            const repeaterContainer4 = document.getElementById("RepeaterContainer4");

             // Show dropdown on focus 
             textBox1.addEventListener("focus", function () {
                 repeaterContainer1.style.display = "block";
                 repeaterContainer2.style.display = "none";
                 repeaterContainer3.style.display = "none";
                 repeaterContainer4.style.display = "none";
             });

             // Filter items as the user types
            textBox1.addEventListener("input", function () {
                const input = textBox1.value.toLowerCase();
                 filterSuggestions("category-link", input);
            });

            //textBox 2
            textBox2.addEventListener("focus", function () {
                repeaterContainer2.style.display = "block";
                repeaterContainer1.style.display = "none";
                repeaterContainer3.style.display = "none";
                repeaterContainer4.style.display = "none";
            });

            textBox2.addEventListener("input", function () {
                const input = textBox2.value.toLowerCase();
                filterSuggestions("category-link", input);
            });

            //textBox3
            textBox3.addEventListener("focus", function () {
                repeaterContainer3.style.display = "block";
                repeaterContainer2.style.display = "none";
                repeaterContainer1.style.display = "none";
                repeaterContainer4.style.display = "none";
            });

            textBox3.addEventListener("input", function () {
                const input = textBox3.value.toLowerCase();
                filterSuggestions("category-link", input);
            });

            //textBox4
            textBox4.addEventListener("focus", function () {
                repeaterContainer4.style.display = "block";
                repeaterContainer2.style.display = "none";
                repeaterContainer3.style.display = "none";
                repeaterContainer1.style.display = "none";
            });

            textBox4.addEventListener("input", function () {
                const input = textBox4.value.toLowerCase();
                filterSuggestions("category-link", input);
            });

             // Hide dropdown when clicking outside
             document.addEventListener("click", function (e) {
                 //if (!textBox1.contains(e.target) && !repeaterContainer1.contains(e.target)) {
                 //    categorySuggestions.style.display = "none";
                 //}
                 if (!e.target.closest(".dropdown-container")) {
                     closeAllDropdowns();
                 }
             });

             
         }


        function filterSuggestions(className, value) {

            const items = document.querySelectorAll("." + className);

            let matchFound = false;

            items.forEach(item => {

                if (item.innerText.toLowerCase().includes(value.toLowerCase())) {

                    item.style.display = "block";

                    matchFound = true;

                } else {

                    item.style.display = "none";

                }

            });

            let noMatchMessage = document.getElementById("no-match-message");

            if (!matchFound) {

                if (!noMatchMessage) {

                    noMatchMessage = document.createElement("div");

                    noMatchMessage.id = "no-match-message";

                    //noMatchMessage.innerText = "No matching suggestions.";

                    items[0]?.parentNode?.appendChild(noMatchMessage);

                }

                noMatchMessage.style.display = "none";

            } else {

                if (noMatchMessage) {

                    noMatchMessage.style.display = "none";

                }

            }

        }
   

        function setTextBox1(value) {

            document.getElementById("<%= TextBox1.ClientID %>").value = value;
            closeAllDropdowns();


        }


        function setTextBox2(value) {
            document.getElementById("<%= TextBox2.ClientID %>").value = value;
            document.getElementById("<%= TextBox3.ClientID %>").value = "";
            closeAllDropdowns();
        }


        function setTextBox3(value) {
            document.getElementById("<%= TextBox3.ClientID %>").value = value;
            closeAllDropdowns();
        }

        function setTextBox4(value) {
            document.getElementById("<%= TextBox4.ClientID %>").value = value;
            closeAllDropdowns();
        }



        <%--function setTextBox2(value) {
            document.getElementById("<%= TextBox2.ClientID %>").value = value;
            document.getElementById("RepeaterContainer2").style.display = "none";
            document.getElementById("<%= TextBox3.ClientID %>").value = "";
        }
        function setTextBox3(value) {
            document.getElementById("<%= TextBox3.ClientID %>").value = value;
            document.getElementById("RepeaterContainer3").style.display = "none";
        }
        function setTextBox4(value) {
            document.getElementById("<%= TextBox4.ClientID %>").value = value;
            document.getElementById("RepeaterContainer4").style.display = "none";
        }--%>
<%--        function setTextBox5(value) {
            document.getElementById("<%= TextBox5.ClientID %>").value = value;
            document.getElementById("RepeaterContainer5").style.display = "none";
        }--%>

        // Also initialize on DOMContentLoaded
        if (document.readyState === "loading") {
            document.addEventListener("DOMContentLoaded", initDropdownEvents);
        } else {
            initDropdownEvents();
        }        async function downloadReceipt() {
            const { jsPDF } = window.jspdf;
            const sourceElement = document.querySelector("#pdfmodal .modal-body");
            const cloneContainer = document.getElementById("pdf-clone-container");
            if (!sourceElement || !cloneContainer) {
                alert("Cannot find content to export.");
                return;
            }
            cloneContainer.innerHTML = "";
            const clone = sourceElement.cloneNode(true);
            clone.style.width = "800px";

            // Add stronger border styling to table elements
            const tables = clone.querySelectorAll("table");
            tables.forEach(table => {
                table.style.borderCollapse = "collapse";
                table.style.border = "2px solid #000";
            });

            const cells = clone.querySelectorAll("td, th");
            cells.forEach(cell => {
                cell.style.border = "1.5px solid #000";
                cell.style.borderColor = "#000";
            });

            const rows = clone.querySelectorAll("tr");
            rows.forEach(row => {
                row.style.borderBottom = "1.5px solid #000";
            });

            cloneContainer.appendChild(clone);

            try {
                const canvas = await html2canvas(clone, {
                    scale: 3,
                    useCORS: true,
                    scrollY: -window.scrollY,
                    allowTaint: true,
                    backgroundColor: "#ffffff"
                });
                const imgData = canvas.toDataURL("image/png");
                const pdf = new jsPDF("p", "pt", "a4");
                const pageWidth = pdf.internal.pageSize.getWidth();
                const pageHeight = pdf.internal.pageSize.getHeight();
                const margin = 40;
                const title = "Owner Details";
                pdf.setFontSize(16);
                pdf.setFont("helvetica", "bold");
                const textWidth = pdf.getTextWidth(title);
                const titleX = (pageWidth - textWidth) / 2;
                pdf.text(title, titleX, 40);
                const imgWidth = pageWidth - margin * 2;
                const fullImageHeight = (canvas.height * imgWidth) / canvas.width;
                const contentYStart = 60;
                const availableHeight = pageHeight - contentYStart - margin;
                let remainingHeight = fullImageHeight;
                let yOffset = 0;
                let pageIndex = 0;
                while (remainingHeight > 0) {
                    const sliceHeight = Math.min(availableHeight, remainingHeight);
                    const sliceCanvas = document.createElement("canvas");
                    sliceCanvas.width = canvas.width;
                    sliceCanvas.height = (sliceHeight * canvas.width) / imgWidth;
                    const ctx = sliceCanvas.getContext("2d");
                    ctx.drawImage(
                        canvas,
                        0, yOffset, canvas.width, sliceCanvas.height,
                        0, 0, canvas.width, sliceCanvas.height
                    );
                    const croppedImg = sliceCanvas.toDataURL("image/png");
                    const yPos = pageIndex === 0 ? contentYStart : margin;
                    pdf.addImage(croppedImg, "PNG", margin, yPos, imgWidth, sliceHeight);
                    remainingHeight -= sliceHeight;
                    yOffset += sliceCanvas.height;
                    pageIndex++;
                    if (remainingHeight > 0) {
                        pdf.addPage();
                    }
                }
                pdf.save("OwnerReport.pdf");
            } catch (err) {
                console.error("Error generating PDF:", err);
                alert("Failed to generate PDF.");
            } finally {
                // Clean up the clone container
                cloneContainer.innerHTML = "";
            }
        }
        function printFlatMaster() {
            var modalContent = document.querySelector("#pdfmodal .modal-body").innerHTML;
            var printWindow = window.open('', '', 'height=700,width=900');
            printWindow.document.write('<html><head><title>Owner Details</title>');
            printWindow.document.write('<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">');
            printWindow.document.write('<style>');
            printWindow.document.write('body { font-size: 12px; margin: 30px; font-family: Arial, sans-serif; }');
            printWindow.document.write('h4 { margin-bottom: 10px; text-align: center; }');
            printWindow.document.write('.table { width: 100%; border-collapse: collapse; margin-top: 20px; }');
            printWindow.document.write('th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }');
            printWindow.document.write('th { background-color: #012970; color: white; text-align: center; }');
            printWindow.document.write('.print-header { text-align: center; margin-bottom: 20px; }');
            printWindow.document.write('</style>');
            printWindow.document.write('</head><body>');
            printWindow.document.write('<div class="print-header">');
            printWindow.document.write('<h4><strong>' + document.querySelector("#pdfmodal h4 strong").innerText + '</strong></h4>');
            printWindow.document.write('</div>');
            printWindow.document.write(modalContent);
            printWindow.document.write('<div style="text-align:center; margin-top:20px;">Printed on: ' + new Date().toLocaleString() + '</div>');
            printWindow.document.write('</body></html>');
            printWindow.document.close();
            printWindow.focus();
            printWindow.print();
            printWindow.close();
        }
        function exportSelectedColumnsToExcel(gridId, selectedColumns = [0, 1, 3], fileName = 'OwnerData.csv', title = "Owner Information") {
            const table = document.getElementById(gridId);
            if (!table) {
                alert("Grid not found!");
                return;
            }
            let csv = '';
            csv += `${title}\n\n`;
            const headerRow = table.rows[0];
            let headerData = [];
            selectedColumns.forEach(index => {
                if (headerRow.cells[index]) {
                    let text = headerRow.cells[index].innerText.trim().replace(/,/g, " ");
                    headerData.push(`"${text}"`);
                }
            });
            csv += headerData.join(",") + "\n";
            for (let i = 1; i < table.rows.length; i++) {
                const row = table.rows[i];
                let rowData = [];
                selectedColumns.forEach(index => {
                    if (row.cells[index]) {
                        let text = row.cells[index].innerText.replace(/,/g, " ").replace(/\n/g, " ").trim();
                        rowData.push(`"${text}"`);
                    }
                });
                csv += rowData.join(",") + "\n";
            }
            const encodedUri = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv);
            const link = document.createElement("a");
            link.setAttribute("href", encodedUri);
            link.setAttribute("download", fileName);
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }
        Sys.Application.add_load(initDropdownEvents);


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

        function validateFileSize(fileInput) {
            if (!fileInput.files || fileInput.files.length === 0) {
                return;
            }

            const file = fileInput.files[0];
            const MAX_SIZE = 10 * 1024 * 1024; // 10 MB

            if (file.size > MAX_SIZE) {
                alert("The file is too large. Maximum allowed size is 10 MB.");
                fileInput.value = ""; // clear file selection
            }
        }

    </script>

</asp:Content>