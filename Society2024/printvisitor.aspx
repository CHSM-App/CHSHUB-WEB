<%@ Page Title="Contact" Language="C#" AutoEventWireup="true" CodeBehind="printvisitor.aspx.cs" Inherits="Society.printvisitor" MasterPageFile="~/Site.Master" %>

<%@ Register Assembly="Microsoft.ReportViewer.WebForms" Namespace="Microsoft.Reporting.WebForms" TagPrefix="rsweb" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <asp:UpdatePanel runat="server" UpdateMode="Conditional">
        <ContentTemplate>

            <div style="padding: 15px">
                <style media="print">
    #MainContent_Button1,
    #MainContent_btnPrint,
    .form-group,
    .dropdown-container,
    .suggestion-list {
        display: none !important;
    }

    #MainContent_GridView1 {
        font-size: 12pt;
        width: 100%;
        border-collapse: collapse;
    }

    #MainContent_GridView1 th,
    #MainContent_GridView1 td {
        border: 1px solid black;
        padding: 8px;
    }
</style>

                <asp:HiddenField ID="society_id" runat="server" />
                <asp:HiddenField ID="building_id" runat="server" />

                <h1 class=" tex0 font-weight-bold " style="color: #012970;">Visitor Reports
                </h1>
                <br />
                <div class="bg-white p-3">
                    <div class="form-group">
                        <div class="row ">
                            <div class="col-sm-2">
                                <asp:Label ID="Label7" runat="server" Text="Building Name"></asp:Label>
                                <asp:Label ID="Label8" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                <asp:Label ID="Label9" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                            </div>
                            <div class="col-sm-2">
                                <div class="dropdown-container">
                                    <asp:TextBox ID="TextBox1" runat="server" CssClass="input-box form-control"
                                        placeholder="Select" autocomplete="off" required="required" />
                                    <div id="RepeaterContainer1" class="suggestion-list" style="width:100%;">
                                        <asp:Repeater ID="Repeater1" runat="server" OnItemCommand="CategoryRepeater_ItemCommand">
                                            <ItemTemplate>
                                                <asp:LinkButton
                                                    ID="lnkCategory"
                                                    runat="server"
                                                    CssClass="suggestion-item link-button category-link"
                                                    Text='<%# Eval("build_name") %>'
                                                    CommandArgument='0'
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
                                <asp:Label ID="Label1" runat="server" Text="Type"></asp:Label>
                                <asp:Label ID="Label2" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                <asp:Label ID="Label3" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                            </div>
                            <div class="col-sm-2">
                                <asp:DropDownList ID="ddl_type" runat="server" AutoPostBack="true" Width="150px">
                                    <asp:ListItem>Select</asp:ListItem>
                                    <asp:ListItem Value="Cab">Cab </asp:ListItem>
                                    <asp:ListItem Value="Service">Home service</asp:ListItem>
                                    <asp:ListItem Value="Delivery">Delivery</asp:ListItem>
                                    <asp:ListItem Value="Guest">Guest & Others</asp:ListItem>

                                </asp:DropDownList>

                            </div>
                        </div>
                    </div>
                    
                  


                    <div class="form-group">
                        <div class="row ">

                            <div class="col-sm-2">
                                <asp:Label ID="lbl_date" runat="server" Text="From Date"></asp:Label>
                                <asp:Label ID="lbl_date_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                            </div>
                            <div class="col-sm-2">
                                <asp:TextBox ID="txt_from" TextMode="Date" runat="server" SelectedDate="<%# DateTime.Today %>"></asp:TextBox>
                            </div>
                            <div class="col-sm-2">
                                <asp:Label ID="Label12" runat="server" Text="To Date"></asp:Label>
                                <asp:Label ID="Label13" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                            </div>
                            <div class="col-sm-2">
                                <asp:TextBox ID="txt_to" TextMode="Date" runat="server"></asp:TextBox>
                            </div>
                        </div>
                    </div>
                </div>
                <br />

                <div align="center">
                    <asp:Button ID="Button1" runat="server" Text="Load Report" OnClick="Button1_Click"
                        class="btn btn-primary" Font-Bold="True" />
                 
                    <br /><br />
                     <asp:Button ID="btnClientPdf" runat="server" Text="Download PDF (Client-Side)" OnClientClick="generatePDF(); return false;" CssClass="btn btn-danger" />

                    <div class="mt-4">
    <asp:GridView ID="GridView1" runat="server" CssClass="table table-bordered table-striped"
        AutoGenerateColumns="false" ShowHeaderWhenEmpty="true" EmptyDataText="No data found."
        HeaderStyle-BackColor="#012970" HeaderStyle-ForeColor="White" Font-Size="Small">
        
        <Columns>
            <asp:BoundField DataField="v_name" HeaderText="Visitor Name" />
            <asp:BoundField DataField="type" HeaderText="Type" />
            <asp:BoundField DataField="in_date" HeaderText="Visit Date" DataFormatString="{0:dd-MM-yyyy}" />
             <asp:BoundField DataField="out_date" HeaderText="Visit Date" DataFormatString="{0:dd-MM-yyyy}" />
            <asp:BoundField DataField="build_name" HeaderText="Building" />
            <asp:BoundField DataField="unit" HeaderText="Flat No." />
        </Columns>
    </asp:GridView>
</div>

                    <rsweb:ReportViewer ID="ReportViewer1" runat="server" Width="69%"></rsweb:ReportViewer>
                </div>
            </div>
        </ContentTemplate> 
    </asp:UpdatePanel>


<script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
<script src="https://html2canvas.hertzen.com/dist/html2canvas.min.js"></script>


<script>
 
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

  
    async function generatePDF() {
        const { jsPDF } = window.jspdf;

        // Get the content to convert — here we target the GridView
        const element = document.getElementById('<%= GridView1.ClientID %>');

        if (!element) {
            alert("No data available to download.");
            return;
        }

        const canvas = await html2canvas(element, {
            scale: 2,
            useCORS: true
        });

        const imgData = canvas.toDataURL('image/png');
        const pdf = new jsPDF('p', 'pt', 'a4');
        const pageWidth = pdf.internal.pageSize.getWidth();
        const pageHeight = pdf.internal.pageSize.getHeight();

        // Calculate width and height for the image in the PDF
        const imgProps = pdf.getImageProperties(imgData);
        const pdfWidth = pageWidth;
        const pdfHeight = (imgProps.height * pdfWidth) / imgProps.width;

        pdf.addImage(imgData, 'PNG', 20, 20, pdfWidth - 40, pdfHeight);

        pdf.save("VisitorReport.pdf");
    }


function setTextBox1(value) {
    document.getElementById("<%= TextBox1.ClientID %>").value = value;
    document.getElementById("RepeaterContainer1").style.display = "none";
}
 
 
Sys.Application.add_load(initDropdownEvents);
 
 
</script>
</asp:Content>
