<%@ Page Title="Home Page" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="pdc_reminder_search.aspx.cs" Inherits="Society.pdc_reminder_search" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <style>
        .resized-model {
            width: 900px;
            height: auto;
            right: 82px;
        }

        @media(max-width: 431px) {
            .resized-model {
                height: auto;
                margin: auto;
                width: 292px;
                margin-top: 168px;
                right: 1px;
            }
        }

        @media(max-width: 590px) {
            .top-row {
                flex-direction: column;
            }

            .w-90 {
                width: 90%;
            }
        }
    </style>



    <div class="box box-primary">
        <div class="box-header with-border">
            <div class="box-body">

                <table width="100%">
                    <tr>
                        <th width="100%" class="">
                            <h1 class=" tex0 font-weight-bold " style="color: #012970;">Pending Cheques
                            </h1>
                        </th>
                    </tr>
                </table>
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <asp:HiddenField ID="v_id" runat="server"></asp:HiddenField>
                        <asp:HiddenField ID="society_id" runat="Server"></asp:HiddenField>
                        <asp:HiddenField ID="id" runat="Server"></asp:HiddenField>
                        <asp:HiddenField ID="owner_id" runat="Server"></asp:HiddenField>
                        <asp:HiddenField ID="build_id" runat="Server"></asp:HiddenField>
                        <asp:HiddenField ID="wing_id" runat="Server"></asp:HiddenField>
                        <asp:HiddenField ID="pdc_rem_id" runat="Server"></asp:HiddenField>


                        <div class="form-group">
                            <div class="row">
                                <div class="col-12">
                                    <div class=" top-row d-flex align-items-center">
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
                                        <button type="button" class="w-90 btn btn-primary" data-toggle="modal" data-target="#edit_model">Add</button>
                                        &nbsp;
          <button class="w-90 btn btn-primary" onclick="printpdcsearch()">Print</button>
                                        &nbsp;
                                        <button class="w-90 btn btn-success" onclick="downloadReceipt()">Download PDF</button>
                                    </div>
                                </div>
                            </div>
                        </div>


                        <div class="form-group">
                            <div class="row ">
                                <div class="col-sm-12">
                                    <div style="width: 100%; overflow: visible;" class="g-Table">
                                        <asp:GridView AllowPaging="true" OnPageIndexChanging="GridView1_PageIndexChanging" PageSize="15" ID="GridView1" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" HeaderStyle-BackColor="lightblue" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" OnSorting="GridView1_Sorting" OnRowUpdating="GridView1_RowUpdating" OnRowDeleting="GridView1_RowDeleting">
                                             <HeaderStyle BackColor="lightblue" CssClass="sticky-header" />
                                            <%--                                            <asp:GridView ID="grid_cust" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped table-dark">--%>
                                            <Columns>
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="30">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="parking_id" ItemStyle-Width="100" Visible="false">
                                                    <ItemTemplate>
                                                        <asp:Label ID="pdc_rem_id" runat="server" Text='<%# Bind("pdc_rem_id")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Owner Name" ItemStyle-Width="200" SortExpression="owner_name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="o_name" runat="server" Text='<%# Bind("name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Building Name" ItemStyle-Width="200" SortExpression="name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="b_id" runat="server" Text='<%# Bind("build_name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Wing Name" ItemStyle-Width="150" SortExpression="w_name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="w_name" runat="server" Text='<%# Bind("unit")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Cheque No" ItemStyle-Width="120" SortExpression="chqno">
                                                    <ItemTemplate>
                                                        <asp:Label ID="chqno" runat="server" Text='<%# Bind("chqno")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Total Amount" ItemStyle-Width="150" SortExpression="che_amount">
                                                    <ItemTemplate>
                                                        <asp:Label ID="che_amount" runat="server" Text='<%# Bind("che_amount")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>


                                                <asp:TemplateField HeaderText="Edit" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit" OnCommand="edit_Command" CommandName="Update" CommandArgument='<%# Bind("pdc_rem_id")%>'> <img src="Images/123.png" /></asp:LinkButton>
                                                        <%-- <asp:Label ID="addr" runat="server" Text='<%# Bind("w_name")%>'></asp:Label>-  NavigateUrl='<%# "wing_search.aspx?w_id=" + Eval("w_id")%>' --%>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Delete" ItemStyle-Width="50" Visible="false">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit551" CommandName="Delete" OnClientClick="return confirm('Are you sure want to delete?');"><img src="Images/delete_10781634.png" height="25" width="25" /> </asp:LinkButton>
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
                <div class="modal fade bs-example-modal-sm" id="edit_model" tabindex="-1" role="dialog" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                    <div class="modal-dialog modal-sm-4">
                        <div class="modal-content resized-model">
                            <div class="modal-header">
                                <%-- <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>--%>
                                <h4 class="modal-title" id="gridSystemModalLabel"><strong>Pending Cheque Reminder</strong></h4>
                            </div>
                            <div class="modal-body" id="invoice_data">

                                <div class="form-group">
                                    <div class="alert alert-danger danger" style="display: none;"></div>
                                </div>
                                <asp:UpdatePanel ID="upnlCountry" runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>


                                        <asp:HiddenField runat="server" ID="owner_name_id" />
                                        <asp:HiddenField runat="server" ID="building_name_id" />

                                        <asp:HiddenField ID="society_name" runat="server" />

                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-2">
                                                    <asp:Label ID="lbl_cust_name" runat="server" Text="Owner Name"></asp:Label>
                                                    <asp:Label ID="lbl_cust_name_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label10" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-4">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox1" runat="server" CssClass="input-box form-control"
                                                            placeholder="Select" autocomplete="off" required="required" Style="width: 200px;" />
                                                        <div id="RepeaterContainer1" class="suggestion-list">
                                                            <asp:Repeater ID="Repeater1" runat="server" OnItemDataBound="Repeater1_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand1">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='<%# Eval("name") %>'
                                                                        CommandArgument='<%# Eval("owner_id") %>'
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
                                                <div class="col-sm-2">
                                                    <asp:Label ID="Label16" runat="server" Text="Buildng-Wing Name"></asp:Label>
                                                    <asp:Label ID="Label17" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label3" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-4">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox2" runat="server" CssClass="input-box form-control"
                                                            placeholder="Select" autocomplete="off" required="required" Style="width: 200px;" />
                                                        <div id="RepeaterContainer2" class="suggestion-list">
                                                            <asp:Repeater ID="Repeater2" runat="server" OnItemDataBound="Repeater2_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand2">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='<%# Eval("name") %>'
                                                                        CommandArgument='<%# Eval("wing_id") %>'
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
                                            </div>
                                        </div>

                                        <div class="form-group">
                                            <div class="row ">

                                                <div class="col-sm-2">
                                                    <asp:Label ID="lbl_pre_mob" runat="server" Text="Mobile No."></asp:Label>
                                                    <asp:Label ID="lbl_pre_mob_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="lbl_pre_mob_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-4">
                                                    <asp:TextBox ID="txt_pre_mob" onkeypress="return event.charCode >= 48 && event.charCode <= 57" CssClass="form-control" runat="server" MaxLength="10" Height="32px" Width="200px" onblur="checkLength(this)" placeholder="Enter Mobile No." AutoPostBack="true" required></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Mobile No
                                                    </div>
                                                </div>
                                                <div class="col-sm-2">
                                                    <asp:Label ID="lbl_pre_addr1" runat="server" Text="Present Address"></asp:Label>
                                                    <asp:Label ID="lbl_pre_addr1_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                </div>
                                                <div class="col-sm-4">
                                                    <asp:TextBox ID="txt_pre_addr1" CssClass="form-control" runat="server" MaxLength="250" Height="32px" Width="200px" placeholder="Enter Present Address" required></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Address
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="form-group">
                                            <div class="row ">

                                                <div class="col-sm-8"></div>
                                                <div class="col-sm-4">
                                                    <asp:TextBox ID="txt_pre_addr2" runat="server" CssClass="not-required" MaxLength="250" Height="32px" Width="200px" placeholder="Enter Present Address 1"></asp:TextBox>
                                                </div>

                                            </div>
                                        </div>

                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-2">
                                                    <asp:Label ID="lbl_add_mob" runat="server" Text="Alternate Mobile No."></asp:Label>
                                                    <asp:Label ID="Label24" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                </div>
                                                <div class="col-sm-4">
                                                    <asp:TextBox ID="txt_add_mob" onkeypress="return event.charCode >= 48 && event.charCode <= 57" runat="server" CssClass="not-required" MaxLength="10" Height="32px" Width="200px" placeholder="Enter Mobile No." TextMode="Phone"></asp:TextBox>
                                                </div>
                                                <div class="col-sm-2">
                                                    <asp:Label ID="lbl_mob" runat="server" Text="E-mail ID"></asp:Label>
                                                    <asp:Label ID="Label1" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    <asp:Label ID="Label4" runat="server" Font-Bold="True" Font-Size="Medium" ForeColor="Black" Text=":"></asp:Label>
                                                </div>
                                                <div class="col-sm-4">
                                                    <asp:TextBox ID="txt_email" CssClass="form-control" Height="32px" Width="200px" placeholder="Enter Email" runat="server" required TextMode="Email"></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Email
                                                    </div>
                                                    </br>
                                                    <asp:RegularExpressionValidator ID="regexEmailValid" runat="server" ValidationExpression="\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*" ControlToValidate="txt_email" Font-Bold="True" ForeColor="red" ErrorMessage="Invalid Email Format" Display="Dynamic"></asp:RegularExpressionValidator>

                                                </div>
                                            </div>
                                        </div>



                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-4">
                                                    <asp:Label ID="lbl_chq_no" runat="server" Text="Cheque No"></asp:Label>
                                                    <asp:Label ID="lbl_chq_no_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="lbl_chq_no_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-3">
                                                    <asp:TextBox ID="txt_chq_no" required="required" CssClass="form-control" runat="server" Height="30px" Width="150px" MaxLength="50" onkeypress="return digit(event);" OnTextChanged="txt_chq_no_TextChanged" placeholder="Cheque No" TextMode="Number"></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Cheque No
                                                    </div>
                                                    <asp:Label ID="Label2" runat="server"></asp:Label>
                                                </div>
                                            </div>
                                            <div class="row mt-1">
                                                <div class="col-sm-4">
                                                    <asp:Label ID="lbl_chq_date" runat="server" Text="Cheque Date"></asp:Label>
                                                    <asp:Label ID="lbl_chq_date_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="lbl_chq_date_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-3">
                                                    <asp:TextBox ID="txt_chq_date" CssClass="form-control" Height="30px" Width="150px" runat="server" TextMode="Date" required="required"></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Date
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="row mt-1">
                                                <div class="col-sm-4">
                                                    <asp:Label ID="lbl_chq_amount" runat="server" Text="Cheque Amount"></asp:Label>
                                                    <asp:Label ID="lbl_chq_amount_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="lbl_chq_amount_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-3">
                                                    <asp:TextBox ID="txt_chq_amount" CssClass="form-control" runat="server" Height="30px" Width="150px" onkeypress="return digit(event);" placeholder="Cheque Amount" required="required" TextMode="Number"></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Amount
                                                    </div>
                                                </div>
                                            </div>
                                        </div>



                                        <div class="form-group">
                                            <div class="row ">
                                                <%--                                                <div class="col-sm-2"></div>
                                                <div class="col-sm-2">
                                                    <asp:Label ID="Label11" runat="server" Text="Cheque Deposited"></asp:Label>
                                                    <br />
                                                    <asp:CheckBox ID="deposite_chk" runat="server" Checked="false" />


                                                </div>
                                                <div class="col-sm-2">
                                                    <asp:Label ID="Label12" runat="server" Text="Cheque Returned"></asp:Label>
                                                    <br />
                                                    <asp:CheckBox ID="return_chk" runat="server" Checked="false" />



                                                </div>
                                                <div class="col-sm-2">
                                                    <asp:Label ID="Label13" runat="server" Text="Cheque Bounced"></asp:Label>
                                                    <br />
                                                    <asp:CheckBox ID="bounce_chk" runat="server" Checked="false" />



                                                </div>--%>



                                                <%--  <div class="col-sm-2">
                                                    <asp:Button ID="btn_next1" runat="server" Text="Add next" class="btn btn-primary" autopostback="true" ValidationGroup="g1" OnClick="btn_next_Click" />
                                                </div>--%>
                                            </div>
                                        </div>

                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-12">
                                                    <div style="width: 800px; overflow: auto;">
                                                        <asp:GridView ID="GridView2" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" HeaderStyle-BackColor="lightblue">

                                                            <Columns>
                                                                <asp:TemplateField HeaderText="No." ItemStyle-Width="30">
                                                                    <ItemTemplate>
                                                                        <asp:Label ID="id" runat="server" Text='<%#Container.DisplayIndex + 1 %>'></asp:Label>
                                                                    </ItemTemplate>
                                                                </asp:TemplateField>
                                                                <asp:TemplateField HeaderText="pdc_id" Visible="false">
                                                                    <ItemTemplate>
                                                                        <asp:Label ID="pdc_rem_id" runat="server" Text='<%#Bind("pdc_rem_id")%>'></asp:Label>
                                                                    </ItemTemplate>
                                                                </asp:TemplateField>
                                                                <asp:TemplateField HeaderText="Cheque No" ItemStyle-Width="100">
                                                                    <ItemTemplate>
                                                                        <asp:Label ID="cheque_no" runat="server" Text='<%#Bind("chqno")%>'></asp:Label>
                                                                    </ItemTemplate>
                                                                </asp:TemplateField>

                                                                <asp:TemplateField HeaderText="Cheque Date" ItemStyle-Width="100">
                                                                    <ItemTemplate>
                                                                        <asp:Label ID="chq_date" runat="server" Text='<%#Bind("che_date", "{0:dd/MM/yyyy}")%>'></asp:Label>
                                                                    </ItemTemplate>
                                                                </asp:TemplateField>

                                                                <asp:TemplateField HeaderText="Amount" ItemStyle-Width="100">
                                                                    <ItemTemplate>
                                                                        <asp:Label ID="chq_amount" runat="server" Text='<%#Bind("che_amount")%>'></asp:Label>
                                                                    </ItemTemplate>
                                                                </asp:TemplateField>
                                                                <asp:TemplateField HeaderText="Deposited">
                                                                    <ItemTemplate>
                                                                        <asp:CheckBox ID="chk_deposited" runat="server" Enabled="false" Checked='<%# Eval("che_dep").ToString() == "1" ? true : false %>' ItemStyle-Width="100"></asp:CheckBox>

                                                                    </ItemTemplate>
                                                                </asp:TemplateField>
                                                                <asp:TemplateField HeaderText="Returned">
                                                                    <ItemTemplate>
                                                                        <asp:CheckBox ID="chk_returned" runat="server" Enabled="false" Checked='<%# Eval("che_ret").ToString() == "1" ? true : false %>' ItemStyle-Width="100"></asp:CheckBox>

                                                                    </ItemTemplate>
                                                                </asp:TemplateField>
                                                                <asp:TemplateField HeaderText="Bounced">
                                                                    <ItemTemplate>
                                                                        <asp:CheckBox ID="chk_bounced" runat="server" Enabled="false" Checked='<%# Eval("che_can").ToString() == "1" ? true : false %>' ItemStyle-Width="100"></asp:CheckBox>

                                                                    </ItemTemplate>
                                                                </asp:TemplateField>
                                                            </Columns>
                                                        </asp:GridView>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>






                                    </ContentTemplate>
                                    <Triggers>
                                        <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                                        <asp:AsyncPostBackTrigger ControlID="btn_next" EventName="Click" />
                                        <asp:AsyncPostBackTrigger ControlID="btn_close" EventName="Click" />
                                    </Triggers>
                                </asp:UpdatePanel>

                            </div>

                            <div class="modal-footer">

                                <div class="form-group">
                                    <div class="row ">
                                        <center>
                                            <asp:Button ID="btn_next" runat="server" Text="Add next" class="btn btn-primary" autopostback="true" ValidationGroup="g1" OnClick="btn_next_Click" />

                                            <asp:Button Visible="false" ID="btn_save" runat="server" Text="Save" class="btn btn-primary" ValidationGroup="g1" OnClick="btn_save_Click" />
                                            <asp:Button ID="btn_delete" runat="server" Text="Delete" class="btn btn-primary" Visible="false" OnClientClick="return confirm('Are you sure want to delete?');" OnClick="btn_delete_Click" />
                                            <asp:Button ID="btn_close" runat="server" Text="Close" class="btn btn-primary" UseSubmitBehavior="False" OnClientClick="resetForm(); return false;" data-dismiss="modal" />

                                        </center>
                                    </div>
                                </div>



                            </div>
                        </div>
                        <!-- /.modal-body -->
                    </div>
                    <!-- /.modal-content -->
                </div>
                <!-- /.modal-dialog -->


            </div>
        </div>
    </div>


    <!-- pdc PDF Modal -->

    <div class="modal fade bs-example-modal-sm" id="pdfmodal" role="form" aria-labelledby="myLargeModalLabel" data-backdrop="static">
        <div class="modal-dialog modal-lg">
            <!-- Changed to modal-lg for better width -->
            <div class="modal-content resized-model">

                <!-- Modal Header -->
                <div class="modal-header" style="justify-content: center;">
                    <h4 class="modal-title text-center"><strong>PDC Reminder Details</strong></h4>
                </div>

                <!-- Modal Body -->
                <div class="modal-body">

                    <!-- Society Name -->
                    <div style="text-align: center; margin-bottom: 10px;">
                        <h4><strong><%= society_name.Value %></strong></h4>
                    </div>

                    <!-- GridView Container -->
                    <div style="padding: 10px; border-radius: 5px; background-color: #f9f9f9;">

                        <asp:GridView ID="GridView3" runat="server"
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

                                <asp:TemplateField HeaderText="No" ItemStyle-Width="30">
                                    <ItemTemplate>
                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                    </ItemTemplate>
                                </asp:TemplateField>

                                <asp:BoundField HeaderText="parking_id" DataField="pdc_rem_id" Visible="false" />

                                <asp:BoundField HeaderText="Owner Name" DataField="name" SortExpression="owner_name" />

                                <asp:BoundField HeaderText="Building Name" DataField="build_name" SortExpression="name" />

                                <asp:BoundField HeaderText="Wing Name" DataField="unit" SortExpression="w_name" />

                                <asp:BoundField HeaderText="Cheque No" DataField="chqno" SortExpression="chqno" />

                                <asp:BoundField HeaderText="Total Amount" DataField="che_amount" SortExpression="che_amount" />
                            </Columns>

                        </asp:GridView>
                    </div>

                </div>
            </div>
        </div>
    </div>

    <div id="pdf-clone-container" style="position: absolute; top: -10000px; left: -10000px;"></div>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>
    <script src="https://html2canvas.hertzen.com/dist/html2canvas.min.js"></script>

    <script>
        let formSubmitted = false;


    </script>

    <!-- Bootstrap core JavaScript-->
  <%--  <script src="vendor/jquery/jquery.min.js"></script>
    <script src="vendor/bootstrap/js/bootstrap.bundle.min.js"></script>--%>

    <!-- Core plugin JavaScript-->
    <%--<script src="vendor/jquery-easing/jquery.easing.min.js"></script>--%>

    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>


    <script>


        async function downloadFlatMaster() {
            const { jsPDF } = window.jspdf;

            const sourceElement = document.querySelector("#pdfFlatModal .modal-body");
            const cloneContainer = document.getElementById("pdf-clone-container");

            if (!sourceElement || !cloneContainer) {
                alert("Cannot find content to export.");
                return;
            }

            // Clear and clone modal body content
            cloneContainer.innerHTML = "";
            const clone = sourceElement.cloneNode(true);
            clone.style.width = `${sourceElement.offsetWidth}px`; // Match original width
            cloneContainer.appendChild(clone);

            try {
                const canvas = await html2canvas(clone, {
                    scale: 2,
                    useCORS: true
                });

                const imgData = canvas.toDataURL("image/png");
                const pdf = new jsPDF("p", "pt", "a4");

                const pageWidth = pdf.internal.pageSize.getWidth();
                const margin = 40;
                const title = "PDC Reminder Details";

                // Centered Heading
                pdf.setFontSize(16);
                pdf.setFont("helvetica", "bold");
                const textWidth = pdf.getTextWidth(title);
                const x = (pageWidth - textWidth) / 2;
                pdf.text(title, x, 40); // Heading Y pos

                // Image Below Heading
                const imgWidth = pageWidth - margin * 2;
                const imgHeight = (canvas.height * imgWidth) / canvas.width;
                const imageY = 60;

                pdf.addImage(imgData, "PNG", margin, imageY, imgWidth, imgHeight);
                pdf.save("pdcReport.pdf");
            } catch (err) {
                console.error("Error generating PDF:", err);
                alert("Failed to generate PDF.");
            }
        }
        async function downloadReceipt() {
            const { jsPDF } = window.jspdf;

            const sourceElement = document.querySelector("#pdfmodal .modal-body");
            const cloneContainer = document.getElementById("pdf-clone-container");


            if (!sourceElement || !cloneContainer) {
                alert("Cannot find content to export.");
                return;
            }

            // Clone modal-body into offscreen div
            cloneContainer.innerHTML = "";
            const clone = sourceElement.cloneNode(true);
            cloneContainer.appendChild(clone);

            try {
                const canvas = await html2canvas(clone, {
                    scale: 2,
                    useCORS: true
                });

                const imgData = canvas.toDataURL("image/png");
                const pdf = new jsPDF("p", "pt", "a4");

                const pageWidth = pdf.internal.pageSize.getWidth();
                const margin = 40;
                const title = "PDC Reminder Details "

                // ✅ Add Centered Heading
                pdf.setFontSize(16);
                pdf.setFont("helvetica", "bold");
                const textWidth = pdf.getTextWidth(title);
                const x = (pageWidth - textWidth) / 2;
                pdf.text(title, x, 40); // Y position = 40pt from top

                // ✅ Add Image Below Heading
                const imgWidth = pageWidth - margin * 2;
                const imgHeight = (canvas.height * imgWidth) / canvas.width;
                const imageY = 60; // leave room for heading

                pdf.addImage(imgData, "PNG", margin, imageY, imgWidth, imgHeight);
                pdf.save("pdcReport.pdf");
            } catch (err) {
                console.error("Error generating PDF:", err);
                alert("Failed to generate PDF.");
            }
        }
        function initDropdownEvents() {

            const textBox1 = document.getElementById("<%= TextBox1.ClientID %>");

            const repeaterContainer1 = document.getElementById("RepeaterContainer1");

            textBox1.addEventListener("focus", function () {

                repeaterContainer1.style.display = "block";

            });

            textBox1.addEventListener("input", function () {

                const input = textBox1.value.toLowerCase();

                filterSuggestions("category-link", input);

            });

            const textBox2 = document.getElementById("<%= TextBox2.ClientID %>");

            const repeaterContainer2 = document.getElementById("RepeaterContainer2");

            textBox2.addEventListener("focus", function () {

                repeaterContainer2.style.display = "block";

            });

            textBox2.addEventListener("input", function () {

                const input = textBox2.value.toLowerCase();

                filterSuggestions("category-link", input);

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

                    noMatchMessage.innerText = "No matching suggestions.";

                    items[0]?.parentNode?.appendChild(noMatchMessage);

                }

                noMatchMessage.style.display = "block";

            } else {

                if (noMatchMessage) {

                    noMatchMessage.style.display = "none";

                }

            }

        }

        function setTextBox1(value) {

            document.getElementById("<%= TextBox1.ClientID %>").value = value;

            document.getElementById("RepeaterContainer1").style.display = "none";

        }
        function setTextBox2(value) {

            document.getElementById("<%= TextBox2.ClientID %>").value = value;

            document.getElementById("RepeaterContainer2").style.display = "none";

        }


        Sys.Application.add_load(initDropdownEvents);

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
        function openModal() {
            $('#edit_model').modal('show');
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
                    window.location.href = 'pdc_reminder_search.aspx';
                }
            });
        }


        function printpdcsearch() {
            var modalContent = document.querySelector("#pdfmodal .modal-body").innerHTML;

            var printWindow = window.open('', '', 'height=700,width=900');
            printWindow.document.write('<html><head><title>PDC Reminder Details</title>');
            printWindow.document.write('<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css">');
            printWindow.document.write('<style>');
            printWindow.document.write('body {font - size: 12px; margin: 30px; font-family: Arial, sans-serif; }');
            printWindow.document.write('h4 {margin - bottom: 10px; text-align: center; }');
            printWindow.document.write('.table {width: 100%; border-collapse: collapse; margin-top: 20px; }');
            printWindow.document.write('th, td {border: 1px solid #ccc; padding: 8px; text-align: left; }');
            printWindow.document.write('th {background - color: #012970; color: white; text-align: center; }');
            printWindow.document.write('.print-header {text - align: center; margin-bottom: 20px; }');
            printWindow.document.write('</style>');
            printWindow.document.write('</head><body>');

            // Add centered headers manually
            printWindow.document.write('<div class="print-header">');
            printWindow.document.write('<h4><strong>' + document.querySelector("#pdfmodal h4 strong").innerText + '</strong></h4>');
            printWindow.document.write('</div>');

            // Add GridView content
            printWindow.document.write(modalContent);

            // Optional: Print timestamp
            const now = new Date();

            const formattedDateTime =
                now.getDate().toString().padStart(2, '0') + '/' +
                (now.getMonth() + 1).toString().padStart(2, '0') + '/' +
                now.getFullYear() + ' ' +
                now.getHours().toString().padStart(2, '0') + ':' +
                now.getMinutes().toString().padStart(2, '0') + ':' +
                now.getSeconds().toString().padStart(2, '0');

            printWindow.document.write('<div style="text-align:center; margin-top:20px;">Printed on: ' + formattedDateTime + '</div>');

            printWindow.document.write('</body></html>');
            printWindow.document.close();
            printWindow.focus();
            printWindow.print();
            printWindow.close();
        }


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
                btn.click();   // ✅ correct
            }
        }


    </script>

</asp:Content>




