<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="square_feet_rate.aspx.cs" Inherits="Society2024.square_feet_rate" MasterPageFile="~/Site.Master" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="ajaxToolkit" %>
<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
    <script type="text/javascript">
       
        function openModal() {
            $('#edit_model').modal('show');
        }


        function digit(evt) {
            if (evt.keyCode < 48 || evt.keyCode > 57) {

                return false;
            }
        }

        function validateAndSubmit() {

            $('#emailmodal').modal('hide');
            return true;
        }
   
        function openEmailModal() {
            $('#emailmodal').modal('show');
        }
    </script>
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

                }, willClose: () => {

                    window.location.href = 'square_feet_rate.aspx';

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
                           
                                <h1 class=" font-weight-bold " style="color: #012970;">Square Feet Rate</h1>
 
                         
                        </th>
                    </tr>
                </table>
              
                 <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                 <ContentTemplate>
                <asp:HiddenField ID="sq_rate_id" runat="server" />
                <asp:HiddenField ID="village_id" runat="Server"></asp:HiddenField>
                <asp:HiddenField ID="house_type_id" runat="server" />
                <asp:HiddenField ID="house_id" runat="server" />
                <asp:HiddenField ID="modified_u_id" runat="server" />

                     <asp:HiddenField  ID="house_type" runat="server"/>

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
                                                AutoPostBack="true"
                                                OnTextChanged="btn_search_Click"
                                                onkeyup="removeFocusAfterTyping()"/>

                                            <ajaxtoolkit:calendarextender
                                                id="CalendarExtender1"
                                                runat="server"
                                                targetcontrolid="txt_search"
                                                popupbuttonid="btn_calendar"
                                                format="yyyy-MM" />

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


                <div class="form-group">
                    <div class="row ">
                        <div class="col-sm-12">
                            <div style="width: 100%; overflow: auto;">
                                <asp:GridView ID="GridView1" runat="server" AllowPaging="true" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" OnPageIndexChanging="GridView1_PageIndexChanging" Pagesize="15" AllowSorting="true" HeaderStyle-BackColor="lightblue" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" OnSorting="GridView1_Sorting" OnRowUpdating="GridView1_RowUpdating">


                                    <Columns>
                                        <asp:TemplateField HeaderText="No" ItemStyle-Width="50">
                                            <ItemTemplate>
                                                <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="Square Feet Rate" SortExpression="sq_rate_id" Visible="false">
                                            <ItemTemplate>
                                                <asp:Label ID="sq_rate_id" runat="server" Text='<%# Bind("sq_rate_id")%>'></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="Rate" SortExpression="rate">
                                            <ItemTemplate>
                                                <asp:Label ID="rate" runat="server" Text='<%# Bind("rate")%>'></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="House Type" SortExpression="house_type">
                                            <ItemTemplate>
                                                <asp:Label ID="ht" runat="server" Text='<%# Bind("house_type")%>'></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="Applied Date" SortExpression="applied_date">
                                            <ItemTemplate>
                                                <asp:Label ID="applied_date" runat="server" Text='<%# Bind("applied_date","{0:dd-MM-yyyy}")%>'></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>

                                        <asp:TemplateField HeaderText="Edit" ItemStyle-Width="50">
                                            <ItemTemplate>
                                                <asp:LinkButton runat="server" ID="edit1" OnCommand="edit_Command" CommandName="Update" CommandArgument='<%# Bind("sq_rate_id")%>'><img src="Images/123.png" /></asp:LinkButton>
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
    <div class="modal-dialog modal-lg"> <!-- changed modal-sm-4 to modal-lg -->
        <div class="modal-content" style="height: auto; width: 1000px;">
            <div class="modal-header">
                <h4 class="modal-title" id="gridSystemModalLabel"><strong>Square Feet Rate</strong></h4>
            </div>

            <div class="modal-body" id="invoice_data">
                <div class="form-group">
                    <div class="alert alert-danger danger" style="display: none;"></div>
                </div>
                <asp:UpdatePanel ID="upnlCountry" runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <div class="form-group">
                            <div class="row ">
                                <div class="col-sm-3">
                                    <asp:Label ID="Label3" runat="server" Text="House Type"></asp:Label>
                                    <asp:Label ID="Label13" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                    <asp:Label ID="Label14" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                </div>
                                <div class="dropdown-container">
                                    <asp:TextBox ID="TextBox1" runat="server" CssClass="input-box form-control"
                                        placeholder="Select" autocomplete="off" required="required" />
                                    <div id="RepeaterContainer1" class="suggestion-list">
                                        <asp:Repeater ID="Repeater1" runat="server" OnItemCommand="CategoryRepeater_ItemCommand" OnItemDataBound="Repeater1_ItemDataBound" >
                                            <ItemTemplate>
                                                <asp:LinkButton
                                                    ID="lnkCategory"
                                                    runat="server"
                                                    CssClass="suggestion-item link-button category-link"
                                                    Text='<%# Eval("house_type") %>'
                                                    CommandArgument='<%# Eval("house_type_id") %>'
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

                            <div class="col-sm-3">
                                <asp:Label ID="Label1" runat="server" Text="Rate/Per sq ft"></asp:Label>
                                <asp:Label ID="Label4" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                <asp:Label ID="Label5" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                            </div>

                            <div class="col-sm-3">
                                <asp:TextBox ID="txt_rate" runat="server" Height="32px" Width="200px" placeholder="Enter Square Feet Rate"></asp:TextBox>
                            </div>
                        </div>

                        <div class="form-group">
                            <div class="row ">
                                <div class="col-sm-3">
                                    <asp:Label ID="Label6" runat="server" Text="Bill Generation Date"></asp:Label>
                                    <asp:Label ID="Label7" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                    <asp:Label ID="Label8" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                </div>
                                <div class="col-sm-3">
                                    <asp:TextBox ID="txt_gen_date" runat="server" Height="32px" Width="200px" TextMode="Date" required autofocus></asp:TextBox>
                                    <br />
                                    <asp:Label ID="Label9" runat="server" Font-Bold="True" ForeColor="Red"></asp:Label>
                                </div>
                                <div class="col-sm-3">
                                    <asp:Label ID="Label10" runat="server" Text="Due Date"></asp:Label>
                                    <asp:Label ID="Label11" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                    <asp:Label ID="Label12" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                </div>
                                <div class="col-sm-3">
                                    <asp:TextBox ID="txt_due" runat="server" Height="32px" Width="200px" TextMode="Date" required autofocus></asp:TextBox>
                                    <br />
                                    <asp:Label ID="Label15" runat="server" Font-Bold="True" ForeColor="Red"></asp:Label>
                                </div>
                            </div>
                        </div>
                        <div class="form-group">
                            <div class="row ">
                                <div class="col-sm-3">
                                    <asp:Label ID="Label2" runat="server" Text="Applied Date"></asp:Label>
                                    <asp:Label ID="Label16" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                    <asp:Label ID="Label18" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                </div>
                                <div class="col-sm-3">
                                    <asp:TextBox ID="txt_applied_date" runat="server" Height="32px" Width="200px" TextMode="Date" required autofocus></asp:TextBox>
                                    <br />
                                    <asp:Label ID="Label26" runat="server" Font-Bold="True" ForeColor="Red"></asp:Label>
                                </div>
                            </div>
                        </div>
                    </ContentTemplate>
                    <Triggers>
                        <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                    </Triggers>
                </asp:UpdatePanel>
            </div>

            <div class="modal-footer justify-content-end">
                <asp:Button ID="Button1" runat="server" Text="Save" CssClass="btn btn-primary" ValidationGroup="g1" OnClick="btn_save_Click" />
                <asp:Button ID="Button2" runat="server" Text="Close" CssClass="btn btn-primary" UseSubmitBehavior="False" OnClientClick="resetForm(); $('#edit_model').modal('hide'); return false;" />
            </div>

        </div>
        <!-- /.modal-content -->
    </div>
    <!-- /.modal-dialog -->
</div>
<!-- /.modal -->

                <!-- /.modal-dialog -->


            </div>
        </div>
    </div>
    <script>
        document.addEventListener("DOMContentLoaded", function () {
            initDropdownEvents();
        });

        function initDropdownEvents() {
            const textBox1 = document.getElementById("<%= TextBox1.ClientID %>");
        const repeaterContainer1 = document.getElementById("RepeaterContainer1");

        if (!textBox1 || !repeaterContainer1) return; // defensive check

        textBox1.addEventListener("focus", function () {
            repeaterContainer1.style.display = "block";
        });

        textBox1.addEventListener("input", function () {
            const input = textBox1.value.trim().toLowerCase();

            if (input === "") {
                repeaterContainer1.style.display = "none";  // hide suggestions if empty input
            } else {
                repeaterContainer1.style.display = "block"; // show suggestions
            }

            filterSuggestions("category-link", input);
        });

        // Optionally hide suggestions if clicked outside textbox or container
        document.addEventListener("click", function(event) {
            if (!textBox1.contains(event.target) && !repeaterContainer1.contains(event.target)) {
                repeaterContainer1.style.display = "none";
            }
        });
    }

    function filterSuggestions(className, value) {
        const items = document.querySelectorAll("." + className);
        let matchFound = false;

        items.forEach(item => {
            if (item.innerText.toLowerCase().includes(value)) {
                item.style.display = "block";
                matchFound = true;
            } else {
                item.style.display = "none";
            }
        });

        let noMatchMessage = document.getElementById("no-match-message");

        // Create no-match message container only once and append to repeaterContainer1
        const repeaterContainer1 = document.getElementById("RepeaterContainer1");

        if (!matchFound) {
            if (!noMatchMessage) {
                noMatchMessage = document.createElement("div");
                noMatchMessage.id = "no-match-message";
                noMatchMessage.style.padding = "5px";
                noMatchMessage.style.color = "#888";
                noMatchMessage.style.fontStyle = "italic";
                noMatchMessage.innerText = "No matching suggestions.";
                repeaterContainer1.appendChild(noMatchMessage);
            }
            noMatchMessage.style.display = "block";
        } else if (noMatchMessage) {
            noMatchMessage.style.display = "none";
        }
    }

    function setTextBox1(value) {
        const textBox1 = document.getElementById("<%= TextBox1.ClientID %>");
            const repeaterContainer1 = document.getElementById("RepeaterContainer1");

            if (textBox1) textBox1.value = value;
            if (repeaterContainer1) repeaterContainer1.style.display = "none";
        }
    </script>


</asp:Content>
