<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ledger_form.aspx.cs" Inherits="Society.ledger" MasterPageFile="~/Site.Master" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="ajaxToolkit" %>
<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">

    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script type='text/javascript'>

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
            $('#edit').modal('show');
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
                    window.location.href = 'ledger_form.aspx';
                }
            });
        }

        function disableSaveButtonIfValid() {
            var btn = document.getElementById('<%= btn_save.ClientID %>');
            var modal = document.getElementById('edit');
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

                return false; // prevent default to avoid double postback
            }

            return false; // prevent postback if not valid
        }
    </script>

    <div class="box box-primary">
        <div class="box-header with-border">
            <div class="box-body">
                <table width="100%">
                    <tr>
                        <th width="100%" class="">
                            <h1 class=" tex0 font-weight-bold " style="color: #012970;">Ledger
                            </h1>
                        </th>
                    </tr>
                </table>
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <asp:HiddenField ID="led_id" runat="server" />
                        <asp:HiddenField ID="society_id" runat="Server"></asp:HiddenField>

                       
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
                                                format="yyyy-MM-dd" />

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

                                        &nbsp;&nbsp;
                <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#edit">Add</button>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="form-group">
                            <div class="row ">
                                <div class="col-sm-12">
                                    <div style="width: 100%; overflow: auto;">
                                        <asp:GridView ID="GridView1" AllowPaging="true" OnPageIndexChanging="GridView1_PageIndexChanging" PageSize="15" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" HeaderStyle-BackColor="lightblue" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" OnRowUpdating="GridView1_RowUpdating" OnRowDeleting="GridView1_RowDeleting" OnSorting="GridView1_Sorting">

                                            <%--                                            <asp:GridView ID="grid_cust" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped table-dark">--%>
                                            <Columns>
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="led_id" ItemStyle-Width="50" SortExpression="name" Visible="false">
                                                    <ItemTemplate>
                                                        <asp:Label ID="led_id" runat="server" Text='<%# Bind("led_id")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Description" Visible="true" SortExpression="led_description">
                                                    <ItemTemplate>
                                                        <asp:Label runat="server" ID="led_description" Text='<%# Bind("led_description")%>'></asp:Label>
                                                        <%-- <asp:Label ID="addr" runat="server" Text='<%# Bind("flat_type")%>'></asp:Label>--%>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Status" Visible="true" SortExpression="led_status">
                                                    <ItemTemplate>
                                                        <asp:Label runat="server" ID="led_status" Text='<%# Bind("led_status")%>'></asp:Label>
                                                        <%-- <asp:Label ID="addr" runat="server" Text='<%# Bind("flat_type")%>'></asp:Label>--%>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Ledger Date" Visible="true" SortExpression="date">
                                                    <ItemTemplate>
                                                        <asp:Label runat="server" ID="led_date" Text='<%# Bind("date","{0:dd-MMM-yyyy}")%>'></asp:Label>
                                                        <%-- <asp:Label ID="addr" runat="server" Text='<%# Bind("flat_type")%>'></asp:Label>--%>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Edit" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit1" OnCommand="edit_Command" CommandName="Update" CommandArgument='<%# Bind("led_id")%>'><img src="Images/123.png" /></asp:LinkButton>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Delete" ItemStyle-Width="50">
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
                <div class="modal fade bs-example-modal-sm" id="edit" role="form" aria-labelledby="mymodel" data-backdrop="static">
                    <div class="modal-dialog modal-sm-4">
                        <div class="modal-content" style="height: auto; width: auto">
                            <div class="modal-header">
                                <h4 class="modal-title" id="gridSystem"><strong>New Ledger</strong></h4>
                            </div>


                            <div class="modal-body" id="invoice_data">
                                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>
                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-4">
                                                    <asp:Label ID="Label1" runat="server" Text="Description:"></asp:Label>
                                                    <asp:Label ID="Label2" runat="server" Text="*" ForeColor="Red" Font-Bold="true"></asp:Label>
                                                </div>
                                                <div class="col-sm-6">
                                                    <asp:TextBox ID="txt_des" CssClass="form-control" Width="200px" Height="32px" placeholder="Enter Description" runat="server" TextMode="MultiLine" required></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Description
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-4">
                                                    <asp:Label ID="Label3" runat="server" Text="Status:"></asp:Label>
                                                    <asp:Label ID="Label4" runat="server" Font-Bold="true" Text="*" ForeColor="Red"></asp:Label>
                                                </div>
                                                <div class="col-sm-6">
                                                    <asp:RadioButton ID="radiobtn1" runat="server" Text="Active" GroupName="led_status" ToolTip="Ledger Active Status" Checked="true"></asp:RadioButton>&nbsp;&nbsp;
                                            <asp:RadioButton ID="radiobtn2" runat="server" Text="Inactive" GroupName="led_status" ToolTip="Ledger Inactive Status"></asp:RadioButton>
                                                </div>
                                            </div>
                                        </div>
                                    </ContentTemplate>
                                    <Triggers>
                                        <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                                    </Triggers>
                                </asp:UpdatePanel>

                                <div class="modal-footer">
                                    <div class="row">
                                        <center>
                                            <asp:Button ID="btn_save" runat="server" OnClientClick="disableSaveButtonIfValid();" Text="Save" class="btn btn-primary" OnClick="btn_save_Click" />
                                            <asp:Button ID="btn_delete" class="btn btn-primary" Visible="false" OnClientClick="return confirm('Are you sure want to delete?');" runat="server" Text="Delete" OnClick="btn_delete_Click" />
                                            <asp:Button ID="btn_close" class="btn btn-primary" runat="server" OnClientClick="resetForm(); return false;" Text="Close" UseSubmitBehavior="False" OnClick="btn_close_Click" data-dismiss="modal" />
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

    <script>
        $('#edit_model').on('hidden.bs.modal', function () {
            $(this).find('form').trigger('reset');
        })


        //function resetForm() {
        //    $('#edit').modal('hide');
        //    document.getElementById("myForm").reset();
        //    // OR
        //    document.getElementById("myForm").querySelectorAll("input[type='text'], input[type='email'], input[type='password']" ,input[type='Dropdown']).forEach(input => input.value = "");
        //}

        //function resetForm2() {
        //    // Hide the modal
        //    console.log("hello");
        //    $('#edit').modal('hide');

        //    // Get the modal content
        //    var modal = document.getElementById('edit');
        //    console.log(modal)
        //    // Reset all text, email, and password inputs
        //    modal.querySelectorAll("input[type='text'], input[type='email'], input[type='password']").forEach(function (input) {
        //        input.value = "";
        //    });

        //    // Reset all dropdowns (select elements)
        //    modal.querySelectorAll("select").forEach(function (select) {
        //        select.selectedIndex = 0;
        //    });

        //    // Reset all radio buttons
        //    modal.querySelectorAll("input[type='radio']").forEach(function (radio) {
        //        radio.checked = false;
        //    });

        //    // Reset all checkboxes
        //    modal.querySelectorAll("input[type='checkbox']").forEach(function (checkbox) {
        //        checkbox.checked = false;
        //    });
        //}

    </script>
</asp:Content>
