<%@ Page Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="meeting_details.aspx.cs" Inherits="Society.meeting_details" %>


<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <style>
        @media(max-width: 630px){
    .top-row{
        flex-direction:column;
    }

    .w-90{
        width:90%;
    }
}
    </style>
    <asp:HiddenField ID="meet_id" runat="Server"></asp:HiddenField>
    <asp:HiddenField ID="society_id" runat="server" />
    <div class="box box-primary">
        <div class="box-header with-border">
            <div class="box-body">
                <table width="100%">
                    <tr>
                        <th width="100%" class="">
                            <h1 class=" tex0 font-weight-bold " style="color: #012970;">Meeting Details
                            </h1>
                        </th>
                    </tr>
                </table>
                <div class="form-group">
                    <div class="row justify-content-center my-3">

                        <div class="top-row d-flex align-items-center gap-2 ">
                            <div class="d-flex align-items-center">

                            <asp:Label ID="lbl_co_name" runat="server" Text="Meeting Date :" CssClass="me-1"></asp:Label>

                            <asp:TextBox ID="txt_date" runat="server" TextMode="Date" Width="170px"></asp:TextBox>&nbsp;&nbsp;

           
                            </div>

                            <asp:Button ID="btn_search" runat="server" Text="Search Meeting" CssClass="btn btn-primary" OnClick="btn_search_Click" />

                        </div>

                    </div>
                </div>
                <div class="form-group">
                    <div class="row ">
                        <div style="width: 100%; overflow: auto;">
                            <asp:GridView AllowPaging="true" OnPageIndexChanging="GridView1_PageIndexChanging" PageSize="15" ID="GridView1" runat="server" CssClass="table table-bordered table-hover table-striped" HeaderStyle-BackColor="LightBlue" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" SkinID="gvSkin" AutoGenerateColumns="false" OnRowDeleting="GridView1_RowDeleting">

                                <Columns>
                                    <asp:TemplateField HeaderText="No" ItemStyle-Width="50">
                                        <ItemTemplate>
                                            <asp:Label ID="no" runat="server" Style="width: 1327px;" Text='<%# Container.DisplayIndex + 1%>'></asp:Label>
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="meet_id" SortExpression="meet_id" Visible="false">
                                        <ItemTemplate>
                                            <asp:Label ID="meet_id" runat="server" Text='<%#Bind("meet_id")%>'></asp:Label>
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="Meeting Date" SortExpression="meeting_date">
                                        <ItemTemplate>
                                            <asp:HyperLink runat="server" ID="HyperLink1" NavigateUrl='<%# "meeting_search.aspx?meet_id=" + Eval("meet_id")%>' Text='<%# Bind("meeting_date","{0:dd-MM-yyyy}")%>'></asp:HyperLink>
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="Meeting Time" SortExpression="meeting_time">
                                        <ItemTemplate>
                                            <asp:Label ID="meet_time" runat="server" Text='<%#Bind( "meeting_time", "{0:hh:MM tt}")%>'></asp:Label>
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="Meeting Subject" SortExpression="subject">
                                        <ItemTemplate>
                                            <asp:Label ID="meet_sub" runat="server" Text='<%#Bind("subject")%>'></asp:Label>
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="Details" SortExpression="details">
                                        <ItemTemplate>
                                            <asp:Label ID="details" runat="server" Text='<%#Bind("details")%>'></asp:Label>
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

        </div>
    </div>

</asp:Content>
