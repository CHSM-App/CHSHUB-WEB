<%@ Page Title="" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="account_setting.aspx.cs" Inherits="Society.account_setting" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
     <div class="box box-primary">
        <div class="box-header with-border">
     
        <div class="box-body">
            <asp:HiddenField ID="acc_set_id" runat="server" />
            <asp:HiddenField ID="society_id" runat="server" />
            <div class="box-header with-border">
                <h3 class="box-title" style="font-weight: bold">Additional /Supplementary Billing</h3>
            </div>
            <div class="form-group">
                <div class="row">
                    <div class="col-sm-2">
                        <asp:Label ID="Label1" runat="server" Text="Additional Member Opening Balance Button"></asp:Label>
                    </div>
                    <div class="col-sm-4">
                        <asp:DropDownList ID="DropDownList1" class="form-control" runat="server">
                            <asp:ListItem Selected="True" Value="0">OFF</asp:ListItem>
                            <asp:ListItem Value="1">ON</asp:ListItem>
                        </asp:DropDownList>
                    </div>
                </div>
            </div>
            <div class="form-group">
                <div class="row">
                    <div class="col-sm-2">
                        <asp:Label ID="Label2" runat="server" Text="Additional Member Charges Button"></asp:Label>
                    </div>
                    <div class="col-sm-4">
                        <asp:DropDownList ID="DropDownList2" class="form-control" runat="server">
                            <asp:ListItem Selected="True" Value="0">OFF</asp:ListItem>
                            <asp:ListItem Value="1">ON</asp:ListItem>
                        </asp:DropDownList>
                    </div>
                </div>
            </div>
            <div class="form-group">
                <div class="row">
                    <div class="col-sm-2">
                        <asp:Label ID="Label3" runat="server" Text="Additional member Charge Allocation"></asp:Label>
                    </div>
                    <div class="col-sm-4">
                        <asp:DropDownList ID="DropDownList3" class="form-control" runat="server">
                            <asp:ListItem Selected="True" Value="0">OFF</asp:ListItem>
                            <asp:ListItem Value="1">ON</asp:ListItem>
                        </asp:DropDownList>
                    </div>
                </div>
            </div>
            <div class="form-group">
                <div class="row">
                    <div class="col-sm-2">
                        <asp:Label ID="Label4" runat="server" Text="Additional Receipts Button"></asp:Label>
                    </div>
                    <div class="col-sm-4">
                        <asp:DropDownList ID="DropDownList4" class="form-control" runat="server">
                            <asp:ListItem Selected="True" Value="0">OFF</asp:ListItem>
                            <asp:ListItem Value="1">ON</asp:ListItem>
                        </asp:DropDownList>
                    </div>
                </div>
            </div>
            <div class="form-group">
                <div class="row">
                    <div class="col-sm-2">
                        <asp:Label ID="Label14" runat="server" Text="Additional Bill Generation Button"></asp:Label>
                    </div>
                    <div class="col-sm-4">
                        <asp:DropDownList ID="DropDownList5" class="form-control" runat="server">
                            <asp:ListItem Selected="True" Value="0">OFF</asp:ListItem>
                            <asp:ListItem Value="1">ON</asp:ListItem>
                        </asp:DropDownList>
                    </div>
                </div>
            </div>
<div class="box-header with-border">
    <h3 class="box-title" style="font-weight: bold">Billing</h3>
</div>

<div class="form-group">
    <div class="row">
        <div class="col-sm-2">
            <asp:Label ID="Label5" runat="server" Text="GST Rounding"></asp:Label>
        </div>
        <div class="col-sm-4">
            <asp:DropDownList ID="DropDownList6" class="form-control" runat="server">
                <asp:ListItem Selected="True" Value="0">OFF</asp:ListItem>
                <asp:ListItem Value="1">ON</asp:ListItem>
            </asp:DropDownList>
        </div>
    </div>
</div>

<div class="form-group">
    <div class="row">
        <div class="col-sm-2">
            <asp:Label ID="Label6" runat="server" Text="Charges Rounding"></asp:Label>
        </div>
        <div class="col-sm-4">
            <asp:DropDownList ID="DropDownList7" class="form-control" runat="server">
                <asp:ListItem Selected="True" Value="0">OFF</asp:ListItem>
                <asp:ListItem Value="1">ON</asp:ListItem>
            </asp:DropDownList>
        </div>
    </div>
</div>

<!-- Rate Per Square Feet -->
<div class="form-group">
    <div class="row">
        <div class="col-sm-2">
            <asp:Label ID="Label15" runat="server" Text="Rate per Sq. Feet"></asp:Label>
        </div>
        <div class="col-sm-4">
            <asp:TextBox ID="txtRatePerSqFeet" runat="server" CssClass="form-control" placeholder="Enter rate"></asp:TextBox>
        </div>
    </div>
</div>

<!-- 2 Wheeler Parking Rate -->
<div class="form-group">
    <div class="row">
        <div class="col-sm-2">
            <asp:Label ID="Label16" runat="server" Text="2 Wheeler Parking Rate"></asp:Label>
        </div>
        <div class="col-sm-4">
            <asp:TextBox ID="txtTwoWheelerRate" runat="server" CssClass="form-control" placeholder="Enter rate"></asp:TextBox>
        </div>
    </div>
</div>

<!-- 4 Wheeler Parking Rate -->
<div class="form-group">
    <div class="row">
        <div class="col-sm-2">
            <asp:Label ID="Label17" runat="server" Text="4 Wheeler Parking Rate"></asp:Label>
        </div>
        <div class="col-sm-4">
            <asp:TextBox ID="txtFourWheelerRate" runat="server" CssClass="form-control" placeholder="Enter rate"></asp:TextBox>
        </div>
    </div>
</div>

            <div class="box-header with-border">
                <h3 class="box-title" style="font-weight: bold">Voucher Entry</h3>
            </div>
            <div class="form-group">
                <div class="row">
                    <div class="col-sm-2">
                        <asp:Label ID="Label7" runat="server" Text="Multi entry in Payment voucher"></asp:Label>
                    </div>
                    <div class="col-sm-4">
                        <asp:DropDownList ID="DropDownList8" class="form-control" runat="server">
                            <asp:ListItem Selected="True" Value="0">OFF</asp:ListItem>
                            <asp:ListItem Value="1">ON</asp:ListItem>
                        </asp:DropDownList>
                    </div>
                </div>
            </div>
            <div class="form-group">
                <div class="row">
                    <div class="col-sm-2">
                        <asp:Label ID="Label8" runat="server" Text="Multi entry in Debit note voucher"></asp:Label>
                    </div>
                    <div class="col-sm-4">
                        <asp:DropDownList ID="DropDownList9" class="form-control" runat="server">
                            <asp:ListItem Selected="True" Value="0">OFF</asp:ListItem>
                            <asp:ListItem Value="1">ON</asp:ListItem>
                        </asp:DropDownList>
                    </div>
                </div>
            </div>
            <div class="form-group">
                <div class="row">
                    <div class="col-sm-2">
                        <asp:Label ID="Label9" runat="server" Text="Multi entry in Credit note voucher"></asp:Label>
                    </div>
                    <div class="col-sm-4">
                        <asp:DropDownList ID="DropDownList10" class="form-control" runat="server">
                            <asp:ListItem Selected="True" Value="0">OFF</asp:ListItem>
                            <asp:ListItem Value="1">ON</asp:ListItem>
                        </asp:DropDownList>
                    </div>
                </div>
            </div>
            <div class="form-group">
                <div class="row">
                    <div class="col-sm-2">
                        <asp:Label ID="Label10" runat="server" Text="Multi entry in Journal voucher"></asp:Label>
                    </div>
                    <div class="col-sm-4">
                        <asp:DropDownList ID="DropDownList11" class="form-control" runat="server">
                            <asp:ListItem Selected="True" Value="0">OFF</asp:ListItem>
                            <asp:ListItem Value="1">ON</asp:ListItem>
                        </asp:DropDownList>
                    </div>
                </div>
            </div>
            <div class="form-group">
                <div class="row">
                    <div class="col-sm-2">
                        <asp:Label ID="Label11" runat="server" Text="Multi entry in Receipt voucher"></asp:Label>
                    </div>
                    <div class="col-sm-4">
                        <asp:DropDownList ID="DropDownList12" class="form-control" runat="server">
                            <asp:ListItem Selected="True" Value="0">OFF</asp:ListItem>
                            <asp:ListItem Value="1">ON</asp:ListItem>
                        </asp:DropDownList>
                    </div>
                </div>
            </div>
            <div class="box-header with-border">
                <h3 class="box-title" style="font-weight: bold">Payment</h3>
            </div>

            <div class="form-group">
                <div class="row">
                    <div class="col-sm-2">
                        <asp:Label ID="Label12" runat="server" Text="Maintain Building Wise Payment"></asp:Label>
                    </div>
                    <div class="col-sm-4">
                        <asp:DropDownList ID="DropDownList13" class="form-control" runat="server">
                            <asp:ListItem Selected="True" Value="0">OFF</asp:ListItem>
                            <asp:ListItem Value="1">ON</asp:ListItem>
                        </asp:DropDownList>
                    </div>

                </div>
                <div class="box-header with-border">
                    <h3 class="box-title" style="font-weight: bold">Reminder</h3>
                </div>

                <div class="form-group">
                    <div class="row">
                        <div class="col-sm-2">
                            <asp:Label ID="Label13" runat="server" Text="Send Remainder Email For Dues"></asp:Label>
                        </div>
                        <div class="col-sm-4">
                            <asp:DropDownList ID="DropDownList14" class="form-control" runat="server">
                                <asp:ListItem Selected="True" Value="0">OFF</asp:ListItem>
                                <asp:ListItem Value="1">ON</asp:ListItem>
                            </asp:DropDownList>
                        </div>
                    </div>
                </div>
            </div>

            <div class="form-group">
                <div class="row">
                    <div class="col-sm-3">
                        <asp:Button ID="btn_save" class="btn btn-primary" runat="server" Text="Save" OnClick="btn_save_Click" />
                    </div>
                </div>
            </div>
           
           
        </div>
    </div>
         </div>
</asp:Content>
