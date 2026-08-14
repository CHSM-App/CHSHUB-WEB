<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="user_login.aspx.cs" Inherits="Society.user_login" %>

<%--<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="Server">--%>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
   
    </head>
<body style="margin: 100px; top: 0px;" >
  
    <form id="form1" runat="server" style="position: inherit; top: 1px; right: 20px" >
   <asp:HiddenField ID="UserLoginId" runat="server" />
    <asp:HiddenField ID="society_id" runat="server" />
         <div class="box box-info">
        <div class="box-header">
            <div class="row ">
                <div class="col-sm-9">
                    <h3 class="panel-title">User Login Details</h3>
                </div>
                <div class="col-sm-3">
                    <asp:Label ID="Label12" runat="server" ForeColor="Red" Text="* Mandatory Fields"></asp:Label>
                </div>

            </div>
        </div>


        <div class="box-body">
           

            <div class="form-group">                              
                <div class="row ">
                    <div class="col-sm-1">
                        <asp:Label ID="lbl_Name" runat="server" Text="Name"></asp:Label>
                        <asp:Label ID="lbl_Name_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                        <asp:Label ID="lbl_short_name_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                        
                    </div>
                    <div class="col-sm-3">
                        <asp:TextBox ID="txt_Name" runat="server" Style="text-transform: capitalize;" class="form-control form-control-lg" required autofocus></asp:TextBox>
                    </div>
                     <div class="col-sm-1">
     <asp:Label ID="lbl_short_name" runat="server" Text="Short Name"></asp:Label>
     <asp:Label ID="lbl_short_name_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>

 </div>
 <div class="col-sm-3">
     <asp:TextBox ID="txt_short_name" runat="server"></asp:TextBox>
 </div>
                    <div class="col-sm-8">
                        <div class="Radiobutton" >
                            <asp:RadioButton ID="RadioButton1" runat="server" width="100px" Text="Active" GroupName="acc" AutoPostBack="true"/>  
                                 <asp:RadioButton ID="RadioButton2" runat="server" width="100px" Text="Inactive" GroupName="acc" AutoPostBack="true"/> 
                            
                          
                        </div>
                    </div>
                </div>
            </div>
                </div>


            <div class="form-group">
                <div class="row ">
                   
                    <div class="col-sm-5"></div>
                </div>
            </div>

            <div class="form-group">
                <div class="row ">
                    <div class="col-sm-2" style="left: 0px; top: 0px">
                        <asp:Label ID="lbl_Address" runat="server" Text="Address"></asp:Label>
                        <asp:Label ID="lbl_Address_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                         <asp:Label ID="Label1" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                    </div>
                    <div class="col-sm-5">
                        <asp:TextBox ID="txt_Address" runat="server"></asp:TextBox>
                    </div>
                    <div class="col-sm-5" style="left: 0px; top: 0px"></div>
                </div>
            </div>

            <div class="form-group">
                <div class="row ">
                    <div class="col-sm-2">
                        <asp:Label ID="lbl_TelNo" runat="server" Text="Telephone No."></asp:Label>
                        <asp:Label ID="lbl_TelNo_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                    </div>
                    <div class="col-sm-5">
                        <asp:TextBox ID="txt_TelNo" runat="server"></asp:TextBox>
                    </div>
                    <div class="col-sm-5"></div>
                </div>
            </div>

            <div class="form-group">
                <div class="row ">
                    <div class="col-sm-2">
                        <asp:Label ID="lbl_Mobile" runat="server" Text="Mobile No."></asp:Label>
                        <asp:Label ID="lbl_Mobile_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                        <asp:Label ID="lbl_Mobile_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                    </div>
                    <div class="col-sm-5">
                        <asp:TextBox ID="txt_Mobile" runat="server" required autofocus></asp:TextBox>
                    </div>
                    <div class="col-sm-5"></div>
                </div>
            </div>

            <div class="form-group">
                <div class="row ">
                    <div class="col-sm-2">
                        <asp:Label ID="lbl_designation" runat="server" Text="User Designation"></asp:Label>
                        <asp:Label ID="lbl_designation_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                       
                    </div>
                    <div class="col-sm-5">
                       <%-- <asp:DropDownList ID="drp_designation" runat="server"></asp:DropDownList>--%>
                        <asp:TextBox ID="txt_designation" runat="server"></asp:TextBox>
                    </div>
                    <div class="col-sm-5">
                        <%--<asp:RequiredFieldValidator ID="rfv_designation" runat="server" ControlToValidate="drp_designation" Display="Dynamic" InitialValue="0" ForeColor="Red" ErrorMessage="Select User Designation"></asp:RequiredFieldValidator>--%>
                    </div>
                </div>
            </div>

            <div class="form-group">
                <div class="row ">
                    <div class="col-sm-2">
                        <asp:Label ID="lbl_UserTypeId" runat="server" Text="User Type"></asp:Label>
                        <asp:Label ID="lbl_UserTypeId_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                        <asp:Label ID="lbl_UserTypeId_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                    </div>
                    <div class="col-sm-5">
                        <asp:DropDownList ID="drp_UserTypeId" Height="28px" Width="170px"  runat="server"></asp:DropDownList>
                    </div>
                    <div class="col-sm-5">
                        <asp:RequiredFieldValidator ID="rfv_UserTypeId" runat="server" ControlToValidate="drp_UserTypeId" Display="Dynamic" InitialValue="0" ForeColor="Red" ErrorMessage="Select User Type"></asp:RequiredFieldValidator>
                    </div>
                </div>
            </div>

          <%--  <div class="form-group">
                <div class="row ">
                    <div class="col-sm-2">
                        <asp:Label ID="lbl_manager" runat="server" Text="Reporting Manager"></asp:Label>
                        <asp:Label ID="lbl_manager_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                        <%--<asp:Label ID="lbl_manager_man" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>--%>
                   <%-- </div>
                    <div class="col-sm-5">--%>
                      <%--  <asp:DropDownList ID="drp_manager" runat="server"></asp:DropDownList>--%>
                       <%-- <asp:TextBox ID="txt_manager" runat="server"></asp:TextBox>
                    </div>
                    <div class="col-sm-5">--%>
                        <%--<asp:RequiredFieldValidator ID="rfv_manager" runat="server" ControlToValidate="drp_manager" Display="Dynamic" InitialValue="0" ForeColor="Red" ErrorMessage="Select Reporting Manager"></asp:RequiredFieldValidator>--%>
                  <%--  </div>
                </div>
            </div>--%>

            <div class="form-group">
                <div class="row ">
                    <div class="col-sm-2">
                        <asp:Label ID="lbl_Emailid" runat="server" Text="Email"></asp:Label>
                        <asp:Label ID="lbl_Emailid_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                         <asp:Label ID="Label2" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                    </div>
                    <div class="col-sm-5">
                        <asp:TextBox ID="txt_Emailid" Style="text-transform: lowercase;" runat="server"></asp:TextBox>
                    </div>
                    <div class="col-sm-5"></div>
                </div>
            </div>

            <div class="form-group">
                <div class="row ">
                    <div class="col-sm-2">
                        <asp:Label ID="lbl_UserName" runat="server" Text=" User Name"></asp:Label>
                        <asp:Label ID="lbl_UserName_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                        <asp:Label ID="lbl_UserName_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                    </div>
                    <div class="col-sm-5">
                        <asp:TextBox ID="txt_UserName" Style="text-transform: lowercase;" runat="server" required autofocus></asp:TextBox>
                    </div>
                    <div class="col-sm-5"></div>
                </div>
            </div>

            <div class="form-group">
                <div class="row ">
                    <div class="col-sm-2">
                        <asp:Label ID="lbl_Password" runat="server" Text="Password"></asp:Label>
                        <asp:Label ID="lbl_Password_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                        <asp:Label ID="lbl_Password_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                    </div>
                    <div class="col-sm-5">
                        <asp:TextBox ID="txt_Password" runat="server" required autofocus></asp:TextBox>
                    </div>
                    <div class="col-sm-5"></div>
                </div>
            </div>

            <%--<div class="form-group">
                <div class="row ">
                    <div class="col-sm-2">
                        <asp:Label ID="lbl_DepId" runat="server" Text="Department"></asp:Label>
                        <asp:Label ID="lbl_DepId_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                        <asp:Label ID="lbl_DepId_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                    </div>
                    <div class="col-sm-5">
                        <asp:DropDownList ID="drp_DepId" runat="server"></asp:DropDownList>
                    </div>
                    <div class="col-sm-5">
                        <asp:RequiredFieldValidator ID="rfv_DepId" runat="server" ControlToValidate="drp_DepId" Display="Dynamic" InitialValue="0" ForeColor="Red" ErrorMessage="Select Department "></asp:RequiredFieldValidator>
                    </div>
                </div>
            </div>--%>

            <div class="form-group">
                <div class="row ">
                    <div class="col-sm-2">
                        <asp:Label ID="lbl_join_dt" runat="server" Text="Join Date"></asp:Label>
                        <asp:Label ID="lbl_join_dt_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                    </div>
                    <div class="col-sm-5">
                        <asp:TextBox ID="txt_join_dt" runat="server" Height="28px" Width="170px"  TextMode="Date"></asp:TextBox>
                    </div>
                    <div class="col-sm-5"></div>
                </div>
            </div>

            <div class="form-group">
                <div class="row ">
                    <div class="col-sm-2">
                        <asp:Label ID="lbl_last_dt" runat="server" Text="Last date"></asp:Label>
                        <asp:Label ID="lbl_last_dt_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                    </div>
                    <div class="col-sm-5">
                        <asp:TextBox ID="txt_last_dt" runat="server" Height="28px" Width="170px"  TextMode="Date"></asp:TextBox>
                    </div>
                   
                    <div class="col-sm-5"></div>
                </div>
            </div>

           <%-- <div class="form-group">
                <div class="row ">
                    <div class="col-sm-2">
                        <asp:Label ID="lbl_branch" runat="server" Text="Branch"></asp:Label>
                        <asp:Label ID="lbl_branch_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                        <asp:Label ID="lbl_branch_branch" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                    </div>
                    <div class="col-sm-5">--%>
                       <%-- <asp:DropDownList ID="drp_branch" runat="server"></asp:DropDownList>--%>
                        <%--<asp:TextBox ID="txt_branch" runat="server"></asp:TextBox>
                    </div>
                    <div class="col-sm-5">--%>
                        <%--<asp:RequiredFieldValidator ID="rfv_branch" runat="server" ControlToValidate="drp_branch" Display="Dynamic" InitialValue="0" ForeColor="Red" ErrorMessage="Select Branch"></asp:RequiredFieldValidator>--%>
                   <%-- </div>
                </div>
            </div>--%>

            <%--<div class="form-group">
                <div class="row ">
                    <div class="col-sm-2">
                        <asp:Label ID="lbl_comp_id" runat="server" Text="Company"></asp:Label>
                        <asp:Label ID="lbl_comp_id_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                    </div>
                    <div class="col-sm-5">
                        <asp:TextBox ID="txt_comp_id" runat="server"></asp:TextBox>
                    </div>
                    <div class="col-sm-5"></div>
                </div>
            </div>

            <div class="form-group">
                <div class="row ">
                    <div class="col-sm-2">
                        <asp:Label ID="lbl_area_id" runat="server" Text="Area"></asp:Label>
                        <asp:Label ID="lbl_area_id_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                    </div>
                    <div class="col-sm-5">
                        <asp:TextBox ID="txt_area_id" runat="server"></asp:TextBox>
                    </div>
                    <div class="col-sm-5"></div>
                </div>
            </div>--%>

        </div>
            </div>
   


    <div class="box box-solid box-default">
        <div class="box-body">
            <div class="form-group">
                <div class="row ">
                    <div class="col-sm-3"></div>
                    <div class="col-sm-5">
                        <asp:Button ID="btn_save" runat="server" Text="Save" class="btn btn-primary" OnClick="btn_save_Click" />
                        <asp:Button ID="btn_delete" runat="server" Text="Delete" class="btn btn-primary" CausesValidation="false" formnovalidate />
                        <asp:Button ID="btn_close" runat="server" Text="Close" class="btn btn-primary" CausesValidation="false" formnovalidate />
                    </div>
                    <div class="col-sm-5"></div>
                </div>
            </div>
        </div>
    </div>
        </form>
</body>
</html>

<%--</asp:Content>--%>
