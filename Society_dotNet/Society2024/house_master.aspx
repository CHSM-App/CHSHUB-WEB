<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="house_master.aspx.cs" Inherits="Society2024.house_master" MasterPageFile="~/Site.Master" %>

<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
    <script type="text/javascript">
        function SuccessEntry() {
            Swal.fire(
                'SUCCESS!',
                'Quotation Entry Successfully Registered!',
                'success'
            )
        }
        function Fail() {
            Swal.fire({
                icon: 'error',
                title: 'Oops...',
                text: 'You Missed Something Empty!',
            })
        }
        function openModal() {
            $('#edit_model').modal('show');
        }
    </script>

    <div class="box box-primary">
        <div class="box-header with-border">
            <div class="box-body">

                <table width="100%">
                    <tr>
                        <th width="100%">
                            <h1 class="bg-primary text-white">
                                <center>Search House</center>
                            </h1>
                        </th>
                    </tr>
                </table>
                <br />

             
                <asp:HiddenField ID="house_id" runat="server" />
                  <div class="form-group">
                    <div class="row ">
                       <div class="col-12">
                           <div class="d-flex align-items-center">

                            <asp:DropDownList ID="search_field" runat="server" Width="200px" Height="32px" OnSelectedIndexChanged="search_field_SelectedIndexChanged">
                                <asp:ListItem Value="house_no">House No</asp:ListItem>
                                <asp:ListItem Value="house_type">House Type</asp:ListItem>
                            </asp:DropDownList>&nbsp;&nbsp;
                      
                             <asp:Panel ID="pnlSearch" runat="server" DefaultButton="btn_search" CssClass="d-flex align-items-center me-2">
                            <asp:TextBox ID="txt_search" Font-Bold="true" Style="text-transform: capitalize;" Width="200px" Height="32px" runat="server" placeholder="Search here"></asp:TextBox>&nbsp;&nbsp;
                        
                            <asp:Button ID="btn_search" runat="server" class="btn btn-primary" OnClick="btn_search_Click" Text="Search" UseSubmitBehavior="False" /></asp:Panel>&nbsp;&nbsp;
                       
                            <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#edit_model">New Entry</button>
                      
                              </div>
                         </div>
                    </div>
                </div>


                <div class="form-group">
                    <div class="row ">
                        <div class="col-sm-12">
                            <div style="width: 100%; overflow: auto;">
                                <asp:GridView ID="GridView1" runat="server" AllowPaging="true" PageSize="20" OnPageIndexChanging="GridView1_PageIndexChanging" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" HeaderStyle-BackColor="lightblue" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" OnRowUpdating="GridView1_RowUpdating" OnSorting="GridView1_Sorting" OnRowDeleting="GridView1_RowDeleting">
                  <%--                                            <asp:GridView ID="grid_cust" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped table-dark">--%>
                                    <Columns>
                                        <asp:TemplateField HeaderText="No" ItemStyle-Width="30">
                                            <ItemTemplate>
                                                <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="house_id" ItemStyle-Width="150px" SortExpression="house_id" Visible="false">
                                            <ItemTemplate>
                                                <asp:Label ID="Label1" runat="server" Text='<%# Bind("house_id")%>'></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="House No" ItemStyle-Width="500px" SortExpression="house_no">
                                            <ItemTemplate>
                                                <asp:Label ID="house_no" runat="server" Text='<%# Bind("house_no")%>'></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>

                                        <asp:TemplateField HeaderText="House Type" ItemStyle-Width="180px" SortExpression="house_type">
                                            <ItemTemplate>
                                                <asp:Label ID="house_type" runat="server" Text='<%# Bind("house_type")%>'></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="Area" ItemStyle-Width="180px" SortExpression="area">
                                            <ItemTemplate>
                                                <asp:Label ID="area" runat="server" Text='<%# Bind("area")%>'></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="Edit" ItemStyle-Width="50">
                                            <ItemTemplate>
                                                <asp:LinkButton runat="server" ID="edit" OnCommand="edit_Command" CommandName="Update" CommandArgument='<%# Bind("house_id")%>'><img src="Images/123.png"/></asp:LinkButton>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="Delete" ItemStyle-Width="50">
                                            <ItemTemplate>
                                                <asp:LinkButton runat="server" ID="delete" CommandName="Delete" OnClientClick="return confirm('Are you sure want to delete?');"><img src="Images/delete_10781634.png" height="25" width="25" /> </asp:LinkButton>
                                            </ItemTemplate>
                                        </asp:TemplateField>

                                    </Columns>
                                </asp:GridView>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="modal fade bs-example-modal-sm" id="edit_model" role="form" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                    <div class="modal-dialog modal-sm-4">
                        <div class="modal-content" style="height: auto; width: 750px;">
                            <div class="modal-header">
                                <h4 class="modal-title" id="gridSystemModalLabel"><strong>Add Flat</strong></h4>
                            </div>
                            <div class="modal-body" id="invoice_data">

                                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>
                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-2">
                                                    <asp:Label ID="Label5" runat="server" Text="House No :"></asp:Label>

                                                    <asp:Label ID="Label10" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-4">
                                                      <asp:TextBox ID="txt_house_no" Width="150px" Height="30px" Style="text-transform: capitalize;" parsely="trigger" required PlaceHolder="Enter House Number" runat="server"></asp:TextBox>
                                                </div>


                                                <div class="col-sm-2">
                                                    <asp:Label ID="lbl_co_name" runat="server" Text="House Type :"></asp:Label>

                                                    <asp:Label ID="lbl_co_name_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-4">
                                                    <asp:DropDownList ID="ddl_type" Width="150px" Height="30px" runat="server"></asp:DropDownList>
                                                    <br />
                                                    <asp:CompareValidator ControlToValidate="ddl_type" ID="CompareValidator1" ValidationGroup="g1" CssClass="errormesg" ErrorMessage="Please select a type" ForeColor="Red" runat="server" Display="Dynamic" Operator="NotEqual" ValueToCompare="select" Type="String" />
                                                </div>

                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <div class="row ">

                                                <div class="col-sm-2">
                                                    <asp:Label ID="Label11" runat="server" Text="Area"></asp:Label>
                                                    <asp:Label ID="Label12" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label13" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>

                                                </div>
                                                <div class="col-sm-4">
                                                     <asp:Label ID="Label7" runat="server" Text="Size(Sq.Ft)"></asp:Label>
                                                    <asp:TextBox ID="txt_area" Width="150px" Height="30px" Style="text-transform: capitalize;" parsely="trigger" AutoPostBack="true" required OnTextChanged="txt_no_TextChanged" PlaceHolder="Enter Flat Number" runat="server"></asp:TextBox>
                                                    <br />
                                                    <asp:Label ID="Label20" ForeColor="Red" Font-Bold="true" runat="server"></asp:Label>
                                                </div>
                                            </div>
                                        </div>
                                       
                                    </ContentTemplate>
                                </asp:UpdatePanel>

                            </div>
                            <div class="modal-footer">
                                <div class="form-group">
                                    <div class="row">
                                        <center>
                                            <asp:Button ID="btn_save" type="button-submit" runat="server" Text="Save" OnClick="btn_save_Click" class="btn btn-primary" ValidationGroup="g1" />
                                            <asp:Button ID="btn_delete" class="btn btn-primary" Visible="false" runat="server" Text="Delete" OnClientClick="return confirm('Are you sure want to delete?');" OnClick="btn_delete_Click" />
                                            <asp:Button ID="btn_close" type="button-close" class="btn btn-primary" runat="server" Text="Close" OnClick="btn_close_Click" UseSubmitBehavior="False" />
                                        </center>
                                        <br />
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <br />




    <br />


</asp:Content>
