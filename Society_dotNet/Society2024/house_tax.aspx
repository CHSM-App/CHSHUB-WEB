<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="house_tax.aspx.cs" Inherits="Society2024.house_tax" MasterPageFile="~/Site.Master" %>


<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
   
            <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
<script type="text/javascript">
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
                window.location.href = 'house_tax.aspx';
            }
        });
    }
            </script>

    <div class="box box-primary">
        <div class="box-header with-border">
            <div class="box-body">

                <table width="100%">
                    <tr>
                        <th width="100%">
                            <h1 class="bg-primary text-white">
                                <center>House Tax</center>
                            </h1>
                        </th>
                    </tr>
                </table>
                <br />

                <asp:HiddenField ID="owner_id" runat="server" />
                <asp:HiddenField ID="house_tax_id" runat="server"></asp:HiddenField>
                <asp:HiddenField ID="village_id" runat="Server"></asp:HiddenField>
              
                <div class="form-group">
                    <div class="row ">
                        <div class="col-12">
                            <div class="d-flex align-items-center">

                                <asp:DropDownList ID="search_field" runat="server" Width="200px" Height="32px">
                                     <asp:ListItem Value="house_no">House No</asp:ListItem>
                                    <asp:ListItem Value="house_type">House Type</asp:ListItem>
                                    <asp:ListItem Value="from_date">Date</asp:ListItem>
                                    <asp:ListItem Value="house_tax_amount">House Type</asp:ListItem>
                                   
                                </asp:DropDownList>&nbsp;&nbsp;
                       
                               <asp:Panel ID="pnlSearch" runat="server" DefaultButton="btn_search" CssClass="d-flex align-items-center me-2">
                                   <asp:TextBox ID="txt_search" Font-Bold="true" Style="text-transform: capitalize;" Width="200px" Height="32px" placeholder="Search here" runat="server"></asp:TextBox>&nbsp;&nbsp;
                       
                            <asp:Button ID="btn_search" runat="server" class="btn btn-primary" Text="Search" UseSubmitBehavior="False" />
                               </asp:Panel>
                                &nbsp;&nbsp;
                        
                            <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#edit_model">New Entry</button>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="form-group">
                    <div class="row ">
                        <div class="col-sm-12">
                            <div style="width: 100%; overflow: auto;">
                                <asp:GridView ID="OwnerGrid" runat="server" AllowPaging="true" PageSize="50" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" OnSorting="OwnerGrid_Sorting" OnRowUpdating="OwnerGrid_RowUpdating" OnRowDeleting="OwnerGrid_RowDeleting" AllowSorting="true" HeaderStyle-BackColor="lightblue" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found">
                                  
                                    <Columns>
                                        <asp:TemplateField HeaderText="No" ItemStyle-Width="50">
                                            <ItemTemplate>
                                                <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="house_tax_id" SortExpression="owner_id" Visible="false">
                                            <ItemTemplate>
                                                <asp:Label runat="server" ID="Label1" Text='<%# Bind("house_tax_id")%>'></asp:Label>
                                               
                                            </ItemTemplate>
                                        </asp:TemplateField>

                                        <asp:TemplateField HeaderText="House No" Visible="true" SortExpression="house_no">
                                            <ItemTemplate>
                                                <asp:Label runat="server" ID="house_no" Text='<%# Bind("house_no")%>'></asp:Label>
                                              
                                            </ItemTemplate>
                                        </asp:TemplateField>

                                        <asp:TemplateField HeaderText="House Type" Visible="true" SortExpression="house_type">
                                            <ItemTemplate>
                                                <asp:Label ID="house_type" runat="server" Text='<%# Bind("house_type")%>'></asp:Label>

                                            </ItemTemplate>
                                        </asp:TemplateField>

                                        <asp:TemplateField HeaderText="From Date" Visible="true" SortExpression="from_date">
                                            <ItemTemplate>
                                                <asp:Label ID="from_date" runat="server" Text='<%# Bind("from_date","{0:yyyy-MM-dd}")%>'></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>

                                        <asp:TemplateField HeaderText="To Date" Visible="true" SortExpression="to_date">
                                            <ItemTemplate>
                                                <asp:Label ID="to_date" runat="server" Text='<%# Bind("to_date","{0:yyyy-MM-dd}")%>'></asp:Label>

                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="House Tax Amount" Visible="true" SortExpression="house_tax_amount">
                                            <ItemTemplate>
                                                <asp:Label ID="house_tax_amount" runat="server" Text='<%# Bind("house_tax_amount")%>'></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="Edit" ItemStyle-Width="50">
                                            <ItemTemplate>
                                                <asp:LinkButton runat="server" ID="edit" CommandName="Update" OnCommand="edit_Command" CommandArgument='<%# Bind("house_tax_id")%>'><img src="Images/123.png"/></asp:LinkButton>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="Delete" ItemStyle-Width="50">
                                            <ItemTemplate>
                                                <asp:LinkButton runat="server" ID="Delete" CommandName="Delete" OnCommand="Delete_Command"><img src="Images/delete_10781634.png" height="25" width="25" /> </asp:LinkButton>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                    </Columns>
                                </asp:GridView>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="modal fade bs-example-modal-sm" id="edit_model" role="form" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                    <div class="modal-dialog modal-sm-4" style="right: 80px">

                        <div class="modal-content" style="height: auto; width: 900px;">
                            <div class="modal-header">
                                <h4 class="modal-title" id="gridSystemModalLabel"><strong>House tax</strong></h4>
                               <%-- <asp:Label ID="receipt_no" runat="server" Font-Bold="True" Font-Size="Medium" Text=":252595"></asp:Label>--%>

                            </div>
                          
                            <div class="modal-body" id="invoice_data">
                                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>
                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-3">
                                                    <asp:Label ID="lbl_acc_no" runat="server" Text="  House No :"></asp:Label>
                                                    <asp:Label ID="lbl_acc_no_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                   <div class="col-sm-3">
                                              <asp:TextBox ID="txt_house_no" Height="32px" Width="200px" runat="server" MaxLength="10" placeholder="Enter House No"></asp:TextBox>
                                               </div>
                                              
                                                <div class="col-sm-3">
                                                 <asp:Label ID="Label2" runat="server" Text="House type"></asp:Label>
                                                <asp:Label ID="Label3" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                               </div>

                                                 <div class="col-sm-3">
                                              <asp:DropDownList ID="ddl_house_type" Height="32px" parsely-trigger="change" Width="200px" runat="server"></asp:DropDownList>
                                              <br />
                                              <asp:CompareValidator ControlToValidate="ddl_house_type" ID="CompareValidator1" ValidationGroup="g1" CssClass="errormesg" ErrorMessage="select house type" Font-Bold="true" ForeColor="Red" runat="server" Display="Dynamic" Operator="NotEqual" ValueToCompare="select" Type="String" />
                                             </div>
                                           
                                            </div>
                                        </div>


                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-3">
                                                    <asp:Label ID="lbl_name" runat="server" Text="From date"></asp:Label>
                                                    <asp:Label ID="lbl_name_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="lbl_name_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-3">
                                                    <asp:TextBox ID="Txtfrom_date" runat="server" Height="32px" Width="200px" TextMode="Date" required></asp:TextBox>
                                                    <%--                        <asp:CalendarExtender ID="CalendarExtender3" runat="server" Enabled="True" TargetControlID="txt_poss_date" Format="dd/MM/yyyy"></asp:CalendarExtender>--%>
                                                </div>



                                                <div class="col-sm-3">
                                                    <asp:Label ID="lbl_mob" runat="server" Text="To date"></asp:Label>
                                                    <asp:Label ID="Label19" runat="server" Font-Bold="True" Font-Size="Medium" ForeColor="Black" Text=":"></asp:Label>
                                                    <asp:Label ID="Label12" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>

                                                </div>
                                                <div class="col-sm-3">
                                                    <asp:TextBox ID="Txt_todate" runat="server" Height="32px" Width="200px" TextMode="Date" required></asp:TextBox>
                                                    <%--                        <asp:CalendarExtender ID="CalendarExtender3" runat="server" Enabled="True" TargetControlID="txt_poss_date" Format="dd/MM/yyyy"></asp:CalendarExtender>--%>
                                                </div>



                                            </div>
                                        </div>

      <div class="form-group">
     <div class="row ">
         <div class="col-sm-3">
             <asp:Label ID="lbl_occup" runat="server" Text="House tax amount"></asp:Label>
             <asp:Label ID="lbl_occup_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
         </div>
         <div class="col-sm-3">
             <asp:TextBox ID="txt_tax_amount" runat="server" Style="text-transform: capitalize;" Height="32px" Width="200px" MaxLength="250" placeholder="Enter tax amount"></asp:TextBox>

         </div>
         <div class="col-sm-6">           
         </div>
         <div class="col-sm-6">
         </div>
     </div>
 </div>               </ContentTemplate>
                                </asp:UpdatePanel>

                                        <div class="modal-footer">
                                            <div class="form-group">
                                                <div class="row">
                                                   <center>
                                                        <asp:Button ID="btn_save" type="button-submit" runat="server" Text="Save" OnClick="btn_save_Click" ValidationGroup="g1" class="btn btn-primary" />
                                                        <asp:Button ID="btn_delete" class="btn btn-primary" Visible="false" runat="server" Text="Delete" OnClick="btn_delete_Click" OnClientClick="return confirm('Are you sure want to delete?');" />
                                                        <asp:Button ID="btn_close" type="button-close" class="btn btn-primary" runat="server" Text="Close" OnClick="btn_close_Click" UseSubmitBehavior="False" />
                                                    </center>
                                                </div>
                                          </div>
                                    </div>
                              </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</asp:Content>
