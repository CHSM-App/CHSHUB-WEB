<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="v_history_table.aspx.cs" Inherits="Society.v_history_table" MasterPageFile="~/Site.Master" %>

<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">


    <table width="100%">
        <tr>
            <th width="100%" class="">
                <h1 class=" tex0 font-weight-bold " style="color: #012970;">History
                </h1>
            </th>
        </tr>
    </table>

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
                                            autocomplete="off"
                                            onkeyup="triggerSearch()" />

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
                                        <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#addHouseModal">Add</button>
                                </div>
                            </div>
                        </div>
                    </div>

    <div class="form-group">
        <div class="row">
            <div class="col-sm-12">
                <div style="width: 100%; overflow: visible;" class="g-Table">
                    <asp:GridView ID="GridView1" runat="server" AutoGenerateColumns="false"
                        CssClass="table table-bordered table-hover table-striped"
                        AllowSorting="true" ShowHeaderWhenEmpty="true"
                        EmptyDataText="No Record Found">
                        <HeaderStyle BackColor="lightblue" CssClass="sticky-header" />
                        <Columns>
                            <asp:TemplateField HeaderText="No" ItemStyle-Width="30">
                                <ItemTemplate>
                                    <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                </ItemTemplate>
                            </asp:TemplateField>

                            <asp:TemplateField HeaderText="House No" ItemStyle-Width="30">
                                <ItemTemplate>
                                    <asp:Label ID="lblRowNumber" Text='<%# Eval("house_no") %>' runat="server" />
                                </ItemTemplate>
                            </asp:TemplateField>

                            <asp:TemplateField HeaderText="Updated By" ItemStyle-Width="30">
                                <ItemTemplate>
                                    <asp:Label ID="lblRowNumber" Text='<%# Eval("updated_by") %>' runat="server" />
                                </ItemTemplate>
                            </asp:TemplateField>

                            <asp:TemplateField HeaderText="Modification Date" ItemStyle-Width="30">
                                <ItemTemplate>
                                    <asp:Label ID="lblRowNumber" Text='<%# Eval("modification_date") %>' runat="server" />
                                </ItemTemplate>
                            </asp:TemplateField>

                            <asp:TemplateField HeaderText="Area" ItemStyle-Width="30">
                                <ItemTemplate>
                                    <asp:Label ID="lblRowNumber" Text='<%# Eval("area") %>' runat="server" />
                                </ItemTemplate>
                            </asp:TemplateField>

                            <asp:TemplateField HeaderText="Property Tax" ItemStyle-Width="30">
                                <ItemTemplate>
                                    <asp:Label ID="lblRowNumber" Text='<%# Eval("gharpatti_charges") %>' runat="server" />
                                </ItemTemplate>
                            </asp:TemplateField>

                            <asp:TemplateField HeaderText="No. of Taps " ItemStyle-Width="30">
                                <ItemTemplate>
                                    <asp:Label ID="lblRowNumber" Text='<%# Eval("no_of_tab") %>' runat="server" />
                                </ItemTemplate>
                            </asp:TemplateField>

                            <asp:TemplateField HeaderText="Water Charges" ItemStyle-Width="30">
                                <ItemTemplate>
                                    <asp:Label ID="lblRowNumber" Text='<%# Eval("water_charges") %>' runat="server" />
                                </ItemTemplate>
                            </asp:TemplateField>

                            <asp:TemplateField HeaderText="Waste Charges" ItemStyle-Width="30">
                                <ItemTemplate>
                                    <asp:Label ID="lblRowNumber" Text='<%# Eval("water_charges") %>' runat="server" />
                                </ItemTemplate>
                            </asp:TemplateField>
                        </Columns>
                    </asp:GridView>
                </div>
            </div>
        </div>
    </div>
</asp:Content>
