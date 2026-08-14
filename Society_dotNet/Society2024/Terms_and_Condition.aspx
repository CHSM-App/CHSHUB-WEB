<%@ Page Title="" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Terms_and_Condition.aspx.cs" ValidateRequest="false" Inherits="Society2024.Terms_and_Condition" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
    <style>
        .resized-model {
            width: 800px;
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
    </style>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script src="https://cdn.jsdelivr.net/npm/tinymce@6/tinymce.min.js"></script>
    <script type='text/javascript'>
        function openModal() {
            $('#edit_model').modal('show');
            tinymce.init({
                selector: '#<%= editor1.ClientID %>',
                plugins: 'advlist autolink lists link image charmap print preview anchor',
                toolbar: 'undo redo | formatselect | bold italic | alignleft aligncenter alignright | bullist numlist outdent indent | link image',
                menubar: false,
                height: 300,
                branding: false, 
                setup: function (editor) {
                    editor.on('init', function () {
                        this.getDoc().body.style.fontSize = '14px';
                    });
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
                    window.location.href = 'Terms_and_Condition.aspx';
                }
            });
        }

        // Re-initialize TinyMCE after UpdatePanel updates
        Sys.Application.add_load(function () {
            if (tinymce.get('<%= editor1.ClientID %>')) {
                tinymce.get('<%= editor1.ClientID %>').remove();
            }
            tinymce.init({
                selector: '#<%= editor1.ClientID %>',
                plugins: 'advlist autolink lists link image charmap print preview anchor',
                toolbar: 'undo redo | formatselect | bold italic | alignleft aligncenter alignright | bullist numlist outdent indent | link image',
                menubar: false,
                height: 300,
                branding: false, 
                setup: function (editor) {
                    editor.on('init', function () {
                        this.getDoc().body.style.fontSize = '14px';
                    });
                }
            });
        });
    </script>

    <div class="box box-primary">
        <div class="box-header with-border">
            <div class="box-body">
                <table width="100%">
                    <tr>
                        <th width="100%">
                            <h1 class="font-weight-bold" style="color: #012970;">Terms and Condition</h1>
                        </th>
                    </tr>
                </table>
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <asp:HiddenField ID="term_id" runat="server" />
                        <asp:HiddenField ID="society_id" runat="server" />
                        <div class="form-group">
                            <div class="row">
                                <div class="col-12">
                                    <asp:Button ID="add_new" runat="server" Text="Add Terms and Conditions" CssClass="btn btn-primary btn-lg px-5" data-toggle="modal" data-target="#edit_model" UseSubmitBehavior="False" OnClientClick="openModal(); return false;" />
                                </div>
                            </div>
                        </div>

                        <div class="form-group">
                            <div class="row">
                                <div class="col-sm-12">
                                    <div style="width: 70%; overflow: auto;">
                                        <asp:GridView ID="GridView1" AllowPaging="true" OnPageIndexChanging="GridView1_PageIndexChanging" PageSize="15" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" OnRowDeleting="GridView1_RowDeleting" OnSorting="GridView1_Sorting" OnRowUpdating="GridView1_RowUpdating" HeaderStyle-BackColor="lightblue">
                                            <Columns>
                                             
                                                <asp:TemplateField HeaderText="t_id" ItemStyle-Width="300" SortExpression="terms_id" Visible="false">
                                                    <ItemTemplate>
                                                        <asp:Label ID="t_id" runat="server" Text='<%# Bind("term_id")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Terms" Visible="true" SortExpression="terms" ItemStyle-Width="500">
                                                    <ItemTemplate>
                                                        <asp:Label runat="server" ID="terms" Text='<%# Bind("terms")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit1" OnCommand="edit_Command" CommandName="Update" CommandArgument='<%# Bind("term_id")%>'><img src="Images/123.png" /></asp:LinkButton>
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
                <div class="modal fade bs-example-modal-sm" id="edit_model" role="form" aria-labelledby="mymodel" data-backdrop="static">
                    <div class="modal-dialog modal-sm-4">
                        <div class="modal-content resized-model">
                            <div class="modal-header">
                                <h4 class="modal-title" id="gridSystem"><strong>Terms and Conditions</strong></h4>
                            </div>
                            <div class="modal-body" id="invoice_data">
                                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>
                                        <div class="form-group">
                                            <div class="row">
                                                <div class="col-sm-12">
                                                    <asp:TextBox ID="editor1" runat="server" TextMode="MultiLine" Width="100%" Rows="10"></asp:TextBox>
                                                </div>
                                            </div>
                                        </div>
                                    </ContentTemplate>
                                    <Triggers>
                                        <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                                    </Triggers>
                                </asp:UpdatePanel>
                            </div>
                            <div class="modal-footer">
                                <asp:Button type="submit" runat="server" class="btn btn-primary" ID="btnSubmit" OnClientClick="tinymce.get('<%= editor1.ClientID %>').save();" OnClick="btnSubmit_Click" Text="Submit" />&nbsp;&nbsp;
                                <asp:Button ID="Button1" runat="server" Text="Close" class="btn btn-primary" UseSubmitBehavior="False" data-dismiss="modal" />
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</asp:Content>