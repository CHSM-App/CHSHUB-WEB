<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="parking_allotment_search.aspx.cs" Inherits="Society.parking_allotment_search" MasterPageFile="~/Site.Master" %>


<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
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

        @media(max-width: 630px) {
            .top-row {
                flex-direction: column;
            }

            .w-90 {
                width: 90%;
            }
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script type="text/javascript">

        function openModal() {
            $('#edit_model').modal('show');
        }

        function digit(evt) {
            if (evt.keyCode < 48 || evt.keyCode > 57) {

                return false;
            }
        }
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
                    window.location.href = 'parking_allotment_search.aspx';
                }
            });
        }

        function disableSaveButtonIfValid() {
            validateVehicleNumber();
            var btn = document.getElementById('<%= btn_save.ClientID %>');
            var modal = document.getElementById('edit_model');
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


    <div class="box box-primary">
        <div class="box-header with-border">
            <div class="box-body">

                <table width="100%">
                    <tr>
                        <th width="100%" class="">
                            <h1 class=" tex0 font-weight-bold " style="color: #012970;">Parking Allotment
                            </h1>
                        </th>
                    </tr>
                </table>
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                    <%--    <asp:HiddenField ID="parking_id" runat="server" />--%>
                        <asp:HiddenField ID="society_name" runat="server" />
                        <asp:HiddenField ID="society_id" runat="Server"></asp:HiddenField> 
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
                                        <button type="button" class="w-90 btn btn-primary" data-toggle="modal" data-target="#edit_model">Add</button>
                                        &nbsp;&nbsp;
                                             <!-- "Print" Button -->
                                        <button type="button" class="w-90 btn btn-primary" onclick="printparkingDetails()">Print</button>

                                        &nbsp;&nbsp;
                                            <button type="button" class="w-90 btn btn-success" usesubmitbehavior="False" onclick="downloadReceipt()">
                                                <i class="fas fa-download me-1"></i>Download Report      
                                            </button>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div class="form-group">
                            <div class="row ">
                                <div class="col-sm-12">
                                    <div style="width: 100%; overflow: visible;" class="g-Table">
                                        <asp:GridView AllowPaging="true" OnPageIndexChanging="GridView1_PageIndexChanging" PageSize="15" ID="GridView1" runat="server" AutoGenerateColumns="false" OnRowUpdating="GridView1_RowUpdating" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" HeaderStyle-BackColor="lightblue" OnSorting="GridView1_Sorting" OnRowDeleting="GridView1_RowDeleting">
                                             <HeaderStyle BackColor="lightblue" CssClass="sticky-header" />
                                            <%--                                            <asp:GridView ID="grid_cust" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped table-dark">--%>
                                            <Columns>
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                 <asp:TemplateField HeaderText="Owner name" SortExpression="name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="name_id" runat="server" Text='<%# Bind("name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>


                                                <asp:TemplateField HeaderText="parking_id" Visible="false" SortExpression="parking_id">
                                                    <ItemTemplate>
                                                        <asp:Label ID="parking_id" runat="server" Text='<%# Bind("vehicle_id")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                 <asp:TemplateField HeaderText="Model" ItemStyle-Width="250px" Visible="true" SortExpression="model_name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="addr" runat="server" Text='<%# Eval("park_for")  +" : "+ Eval("model_name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Vehicle no" SortExpression="vehicle_no">
                                                    <ItemTemplate>
                                                        <asp:Label runat="server" ID="HyperLink1" Text='<%# Bind("vehicle_no")%>'></asp:Label>
                                                        <%-- <asp:Label ID="addr" runat="server" Text='<%# Bind("subject")%>'></asp:Label>--%>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                               
                                                <asp:TemplateField HeaderText="Parking No" ItemStyle-Width="250px" Visible="true" SortExpression="parking_no">
                                                    <ItemTemplate>
                                                        <asp:Label ID="add1r" runat="server" Text='<%# Bind("parking_no")%>'></asp:Label>

                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Edit" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit" OnCommand="edit_Command" CommandName="Update" CommandArgument='<%# Bind("vehicle_id")%>'><img src="Images/123.png"/></asp:LinkButton>
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
                    <Triggers><asp:AsyncPostBackTrigger ControlID ="GridView1" EventName ="RowCommand" /></Triggers>
                </asp:UpdatePanel>

                <div class="modal fade bs-example-modal-sm" id="edit_model" role="form" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                    <div class="modal-dialog modal-sm-4">
                        <div class="modal-content resized-model">
                            <div class="modal-header"> 
                                <h4 class="modal-title" id="gridSystemModalLabel"><strong>Parking Allotment Details</strong></h4>
                            </div>
                            <div class="modal-body" id="invoice_data">

                                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>
                                        <asp:HiddenField ID="flat_id" runat="server" />
                                        <asp:HiddenField ID="vehicle_id" runat="server" />
                                        <asp:HiddenField ID="place_id" runat="server" />
                                        <asp:HiddenField ID="vehicle_type_id" runat="server" />
                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-4">
                                                    <asp:Label ID="lbl_co_name" runat="server" Text="Owner name"></asp:Label>
                                                    <asp:Label ID="lbl_co_name_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="lbl_co_name_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-6">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox1" Style="width: 200px;" runat="server" CssClass="input-box form-control"
                                                            placeholder="Select owner" autocomplete="off" required="required" />
                                                        <div id="RepeaterContainer1" class="suggestion-list">
                                                            <asp:Repeater ID="Repeater_1" runat="server" OnItemDataBound="Repeater_1_ItemDataBound" OnItemCommand="Repeater_1_ItemCommand">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='<%# Eval("name") %>'
                                                                        CommandArgument='<%# Eval("flat_id") %>'
                                                                        CommandName="SelectCategory"
                                                                        OnClientClick="setTextBox1(this.innerText); return true;" />
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
                                        <%-- repater 2oooo --%>

                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-4">
                                                    <asp:Label ID="Label1" runat="server" Text="Vehicle No "></asp:Label>
                                                    <asp:Label ID="Label2" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label3" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-6">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox2" Style="width: 200px;" runat="server" CssClass="input-box form-control"
                                                            placeholder="Select vehicle" autocomplete="off" required="required" />
                                                        <div id="RepeaterContainer2" class="suggestion-list">
                                                            <asp:Repeater ID="Repeater2" runat="server" OnItemDataBound="Repeater2_ItemDataBound" OnItemCommand="Repeater2_ItemCommand">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='<%# Eval("vehicle_no") %>'
                                                                       CommandArgument='<%# Eval("vehicle_type") + "|" + Eval("vehicle_id") %>'

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
                                                <div class="col-sm-4">
                                                    <asp:Label ID="Label4" runat="server" Text="parking place"></asp:Label>
                                                    <asp:Label ID="Label5" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label6" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-6">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox3" Style="width: 200px;" runat="server" CssClass="input-box form-control"
                                                            placeholder="Select Designation" autocomplete="off" required="required" />
                                                        <div id="RepeaterContainer3" class="suggestion-list">
                                                            <asp:Repeater ID="Repeater3" runat="server" OnItemDataBound="Repeater3_ItemDataBound" OnItemCommand="Repeater3_ItemCommand">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='<%# Eval("parking_no") %>'
                                                                        CommandArgument='<%# Eval("place_id") %>'
                                                                        CommandName="SelectCategory"
                                                                        OnClientClick="setTextBox3(this.innerText);" />
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




                                    </ContentTemplate>
                                    <Triggers>
                                        <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                                    </Triggers>
                                </asp:UpdatePanel>

                            </div>
                            <div class="modal-footer">
                                <div class="form-group">
                                    <div class="row">
                                        <center>
                                            <asp:Button ID="btn_save" type="button-submit" runat="server" OnClientClick="disableSaveButtonIfValid();" Text="Save" OnClick="btn_save_Click" class="btn btn-primary" ValidationGroup="g1" />
                                            <asp:Button ID="btn_delete" class="btn btn-primary" Visible="false" runat="server" Text="Delete" OnClick="btn_delete_Click" OnClientClick="return confirm('Are you sure want to delete?');" />
                                            <asp:Button ID="btn_close" runat="server" Text="Close" class="btn btn-primary" UseSubmitBehavior="False" OnClientClick="resetForm(); return false;" data-dismiss="modal" />

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
    <!--  PDF Modal -->

    <div class="modal fade bs-example-modal-sm" id="pdfmodal" role="form" aria-labelledby="myLargeModalLabel" data-backdrop="static">
        <div class="modal-dialog modal-lg">
            <!-- Changed to modal-lg for better width -->
            <div class="modal-content resized-model">

                <!-- Modal Header -->
                <div class="modal-header" style="justify-content: center;">
                    <h4 class="modal-title text-center"><strong>Rental Details</strong></h4>
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
                                <asp:TemplateField HeaderText="No">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Font-Bold="True" CssClass="grid-header" />
                                    <ItemStyle Width="50px" HorizontalAlign="Center" VerticalAlign="Middle" CssClass="grid-item" />
                                    <ItemTemplate>
                                        <asp:Label ID="lblRowNumber" runat="server" Text='<%# Container.DataItemIndex + 1 %>' CssClass="centered-text" />
                                    </ItemTemplate>
                                </asp:TemplateField>

                                <asp:BoundField HeaderText="parking_id" DataField="parking_id" SortExpression="parking_id" Visible="false" />

                                <asp:BoundField HeaderText="Name" DataField="name" SortExpression="name">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Font-Bold="True" CssClass="grid-header" />
                                    <ItemStyle Width="180px" HorizontalAlign="Center" VerticalAlign="Middle" CssClass="grid-item" />
                                </asp:BoundField>

                                <asp:BoundField HeaderText="Contact No" DataField="pre_mob" SortExpression="contact_no">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Font-Bold="True" CssClass="grid-header" />
                                    <ItemStyle Width="150px" HorizontalAlign="Center" VerticalAlign="Middle" CssClass="grid-item" />
                                </asp:BoundField>

                                <asp:BoundField HeaderText="Vehicle No" DataField="vehicle_no" SortExpression="vehicle_no">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Font-Bold="True" CssClass="grid-header" />
                                    <ItemStyle Width="150px" HorizontalAlign="Center" VerticalAlign="Middle" CssClass="grid-item" />
                                </asp:BoundField>
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

    <script>

        async function downloadReceipt() {
            const { jsPDF } = window.jspdf;

            const sourceElement = document.querySelector("#pdfmodal .modal-body");
            const cloneContainer = document.getElementById("pdf-clone-container");

            if (!sourceElement || !cloneContainer) {
                alert("Cannot find content to export.");
                return;
            }

            // Clear previous clone
            cloneContainer.innerHTML = "";
            const clone = sourceElement.cloneNode(true);
            clone.style.width = "800px"; // fixed width
            clone.style.backgroundColor = "#fff"; // white background

            // Style tables
            clone.querySelectorAll("table").forEach(table => {
                table.style.borderCollapse = "collapse";
                table.style.width = "100%";
            });
            clone.querySelectorAll("table, th, td").forEach(el => {
                el.style.border = "1px solid #000";
                el.style.padding = "5px";
                el.style.textAlign = "left"; // left align text
            });
            clone.querySelectorAll("th").forEach(th => {
                th.style.fontWeight = "bold";
                th.style.textAlign = "left"; // left align headers too
            });

            cloneContainer.appendChild(clone);

            try {
                const canvas = await html2canvas(clone, {
                    scale: 2,
                    useCORS: true,
                    allowTaint: true,
                    scrollY: -window.scrollY,
                });

                const imgData = canvas.toDataURL("image/png");
                const pdf = new jsPDF("p", "pt", "a4");
                const pageWidth = pdf.internal.pageSize.getWidth();
                const margin = 40;
                const title = "Parking Details";

                // Add Centered Title
                pdf.setFontSize(16);
                pdf.setFont("helvetica", "bold");
                const textWidth = pdf.getTextWidth(title);
                const x = (pageWidth - textWidth) / 2;
                pdf.text(title, x, 40);

                // Add table/image below title
                const imgWidth = pageWidth - margin * 2;
                const imgHeight = (canvas.height * imgWidth) / canvas.width;
                const imageY = 60; // space below header

                pdf.addImage(imgData, "PNG", margin, imageY, imgWidth, imgHeight);
                pdf.save("ParkingReport.pdf");
            } catch (err) {
                console.error("Error generating PDF:", err);
                alert("Failed to generate PDF.");
            }
        }


        function validateVehicleNumber() {
            const input = document.getElementById('txt_vehical_no');

            if (!input) return;

            const vehicleNumber = input.value.trim().toUpperCase();
            const regex = /^[A-Z]{2}\d{1,2}[A-Z]{1,2}\d{4}$/;

            if (regex.test(vehicleNumber)) {
                input.classList.remove('is-invalid');
                input.classList.add('is-valid');
            } else {
                input.classList.remove('is-valid');
                input.classList.add('is-invalid');
            }
        }

       

    
        function closeAllDropdowns() {
            document.getElementById("RepeaterContainer1").style.display = "none";
            document.getElementById("RepeaterContainer2").style.display = "none";
            document.getElementById("RepeaterContainer3").style.display = "none";           
        }


        function initDropdownEvents() {

            const textBox1 = document.getElementById("<%= TextBox1.ClientID %>");
            const textBox2 = document.getElementById("<%= TextBox2.ClientID %>");
            const textBox3 = document.getElementById("<%= TextBox3.ClientID %>");
            
            const repeaterContainer1 = document.getElementById("RepeaterContainer1");
            const repeaterContainer2 = document.getElementById("RepeaterContainer2");
            const repeaterContainer3 = document.getElementById("RepeaterContainer3");

            //textBox1
            textBox1.addEventListener("focus", function () {
                repeaterContainer1.style.display = "block";
                repeaterContainer2.style.display = "none";
                repeaterContainer3.style.display = "none";
            });

            textBox1.addEventListener("input", function () {
                const input = textBox1.value.toLowerCase();
                filterSuggestions("category-link", input);
            });

            //textBox2
            textBox2.addEventListener("focus", function () {
                repeaterContainer2.style.display = "block";
                repeaterContainer1.style.display = "none";
                repeaterContainer3.style.display = "none";
            });

            textBox2.addEventListener("input", function () {
                const input = textBox2.value.toLowerCase();
                filterSuggestions("category-link", input);
            });

            //textBox3
            textBox3.addEventListener("focus", function () {
                repeaterContainer3.style.display = "block";
                repeaterContainer1.style.display = "none";
                repeaterContainer2.style.display = "none";
            });

            textBox3.addEventListener("input", function () {
                const input = textBox3.value.toLowerCase();
                filterSuggestions("category-link", input);
            });

            // Close dropdown when clicking anywhere else
            document.addEventListener("click", function (e) {
                if (!e.target.closest(".dropdown-container")) {
                    closeAllDropdowns();
                }
            });

        }

         
        
        Sys.Application.add_load(initDropdownEvents);




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

                    //noMatchMessage.innerText = "No matching suggestions.";

                    items[0]?.parentNode?.appendChild(noMatchMessage);

                }

                noMatchMessage.style.display = "none";

            } else {

                if (noMatchMessage) {
                    noMatchMessage.style.display = "none";                   
                }

            }

        }


        function setTextBox1(value) {
            document.getElementById("<%= TextBox1.ClientID %>").value = value;
            closeAllDropdowns();
        }
        function setTextBox2(value) {
            document.getElementById("<%= TextBox2.ClientID %>").value = value;            
            closeAllDropdowns();
        }
        function setTextBox3(value) {
            document.getElementById("<%= TextBox3.ClientID %>").value = value;
            closeAllDropdowns();
        }

     
        function printparkingDetails() {
            var modalContent = document.querySelector("#pdfmodal .modal-body").innerHTML;

            var printWindow = window.open('', '', 'height=700,width=900');
            printWindow.document.write('<html><head><title>Rental Details</title>');
            printWindow.document.write('<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css">');
            printWindow.document.write('<style>');
            printWindow.document.write('body { font-size: 12px; margin: 30px; font-family: Arial, sans-serif; }');

            // Title style: centered, bold, black
            printWindow.document.write('.print-title { text-align: center; font-weight: bold; color: black; font-size: 16px; margin-bottom: 20px; }');

            // Table styles
            printWindow.document.write('.table { width: 100%; border-collapse: collapse; margin-top: 20px; }');
            printWindow.document.write('th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }');
            printWindow.document.write('th { background-color: #012970; color: white; font-weight: bold; text-align: center; }');
            printWindow.document.write('</style>');
            printWindow.document.write('</head><body>');

            // Add title at top
            printWindow.document.write('<div class="print-title">Rental Details</div>');

            // Add table content
            printWindow.document.write(modalContent);

            // Optional: Print timestamp
            const now = new Date();
            const formattedDate = now.getDate().toString().padStart(2, '0') + '/' +
                (now.getMonth() + 1).toString().padStart(2, '0') + '/' +
                now.getFullYear();
            const formattedTime = now.toLocaleTimeString();
            printWindow.document.write('<div style="text-align:center; margin-top:20px;">Printed on: ' + formattedDate + ' ' + formattedTime + '</div>');

            printWindow.document.write('</body></html>');
            printWindow.document.close();
            printWindow.focus();
            printWindow.print();
            printWindow.close();
        }

        Sys.Application.add_load(initDropdownEvents);



    </script>



</asp:Content>
