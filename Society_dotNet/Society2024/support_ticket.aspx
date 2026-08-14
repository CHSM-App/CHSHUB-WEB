<%@ Page Language="C#" Async="true" AutoEventWireup="true" CodeBehind="support_ticket.aspx.cs" Inherits="Society.support_ticket" MasterPageFile="~/Site.Master" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <style>
        .img-thumbnail {
            max-height: 200px;
            object-fit: cover;
        }

        .border-left-primary {
            border-left: 5px solid #007bff;
            padding-left: 10px;
        }

        .chat-message {
            margin-bottom: 1rem;
            clear: both;
        }

        .user-message .message-content {
            background-color: #f8f9fa;
            color: #333;
            max-width: 60%;
            text-align: left;
        }

        .admin-message .message-content {
            background-color: #007bff;
            color: white;
            max-width: 60%;
            text-align: left;
        }

        .text-right .message-content {
            float: right;
        }

        .text-left .message-content {
            float: left;
        }

        #chatContainer {
            padding: 10px;
        }

        .chat-bubble {
            display: flex;
            margin-bottom: 15px;
            max-width: 75%;
        }

            .chat-bubble.user {
                justify-content: flex-start;
            }

            .chat-bubble.admin {
                justify-content: flex-end;
                margin-left: auto;
            }

            .chat-bubble .message-content {
                padding: 0;
                border-radius: 15px;
                max-width: 100%;
                position: relative;
                box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
                overflow: hidden;
                word-wrap: break-word;
            }

            /* USER MESSAGE */
            /* USER MESSAGE - Flat Card Style to Match Admin */
            .chat-bubble.user .message-content {
                background-color: #f9f9f9; /* Same as before */
                color: #333;
                border: 1px solid #e0e0e0;
                box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
                border-radius: 12px; /* Remove curve */
                overflow: hidden;
            }

            /* Header/Author Label */
            .chat-bubble.user .message-author {
                background-color: #dee2e6; /* Same as before */
                color: #212529;
                padding: 8px 12px;
                font-weight: bold;
                font-size: 0.85rem;
                border-bottom: 1px solid #ccc;
                border-top-left-radius: 0;
                border-top-right-radius: 0;
            }

            /* Body Text */
            .chat-bubble.user .message-text {
                background-color: #f8f9fa; /* Same as before */
                color: #333;
                padding: 12px 15px;
                font-size: 0.95rem;
                line-height: 1.5;
                white-space: pre-wrap;
                border-bottom-left-radius: 0;
                border-bottom-right-radius: 0;
            }


            /* ADMIN MESSAGE - Professional Card Style */
            .chat-bubble.admin .message-content {
                background-color: #f9f9f9; /* Light neutral container */
                color: #333333; /* Standard dark text */
                border: 1px solid #e0e0e0; /* Light border for definition */
                border-radius: 12px;
                box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05); /* Subtle shadow */
            }

            /* Header/Author Label */
            .chat-bubble.admin .message-author {
                background-color: #a9cefc; /* Slate blue */
                color: #ffffff; /* White text for contrast */
                padding: 8px 12px;
                font-weight: bold;
                font-size: 0.85rem;
                border-top-left-radius: 6px;
                border-top-right-radius: 6px;
            }

            /* Body Text */
            .chat-bubble.admin .message-text {
                background-color: #ffffff; /* Clean white background */
                color: #333333; /* Readable dark grey text */
                padding: 12px 15px;
                font-size: 0.95rem;
                line-height: 1.5;
                white-space: pre-wrap;
                border-bottom-left-radius: 6px;
                border-bottom-right-radius: 6px;
            }


        .message-time {
            font-size: 0.8rem;
            color: #ccc;
            margin-top: 5px;
            padding: 0 15px 10px;
        }

        .chat-input {
            background-color: #ffffff;
            padding-top: 10px;
            border-top: 1px solid #ddd;
            display: flex;
            flex-wrap: wrap;
            align-items: center;
        }

            .chat-input textarea {
                resize: none;
                flex-grow: 1;
                min-height: 70px;
                margin-right: 10px;
            }
    </style>

    <div class="box-primary">
        <table width="100%">
            <tr>
                <th width="100%">
                    <h1 class="font-weight-bold" style="color: #012970;">HelpDesk</h1>
                </th>
            </tr>
        </table>

        <asp:UpdatePanel runat="server" UpdateMode="Conditional">
            <ContentTemplate>

                <asp:HiddenField ID="society_id" runat="server" />

        

                <div class="form-group">
                    <div class="row">
                        <div class="col-12">
                            <div class="d-flex align-items-center">
                                <div class="search-container">
                                    <asp:TextBox
                                        ID="txt_search"
                                        CssClass="aspNetTextBox"
                                        PlaceHolder="Search here"
                                        runat="server"
                                        TextMode="Search"
                                        AutoPostBack="true"
                                        autocomplete="off"
                                        onkeyup="filterTable()" />

                                    <div class="input-buttons">
                                        <button
                                            id="btn_search"
                                            type="submit"
                                            class="search-button2"
                                            runat="server"
                                            onclick="filterTable()">
                                            <span class="material-symbols-outlined">search</span>
                                        </button>
                                    </div>
                                </div>

                                &nbsp;&nbsp;
                                <asp:CheckBox runat="server" Text="Urgent" CssClass="mr-2" />
                            </div>
                        </div>
                    </div>
                </div>

                <br />
                <br />

                <div class="form-group">
                    <div class="col-sm-12">
                        <div style="width: 100%; overflow: auto;" class="g-Table">
                            <asp:GridView
                                ID="GridView1"
                                runat="server"
                                AllowPaging="true"
                                AllowSorting="true"
                                PageSize="15"
                                AutoGenerateColumns="false"
                                OnPageIndexChanging="GridView1_PageIndexChanging"
                                OnRowCommand="GridView1_RowCommand"
                                CssClass="table table-bordered table-hover table-striped"
                                HeaderStyle-BackColor="lightblue"
                                ShowHeaderWhenEmpty="true"
                                OnRowDataBound="GridView1_RowDataBound"
                                EmptyDataText="No Record Found">

                                <Columns>
                                    <asp:TemplateField HeaderText="No" ItemStyle-Width="20">
                                        <ItemTemplate>
                                            <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                        </ItemTemplate>
                                    </asp:TemplateField>

                                    <asp:TemplateField HeaderText="Helpdesk_id" ItemStyle-Width="30" Visible="false">
                                        <ItemTemplate>
                                            <asp:Label ID="lblHelpdeskId" Text='<%# Bind("helpdesk_id") %>' runat="server" />
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="Helpdesk_id" ItemStyle-Width="30" Visible="false">
                                        <ItemTemplate>
                                            <asp:Label ID="lblownerId" Text='<%# Bind("owner_id") %>' runat="server" />
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="flat_id" ItemStyle-Width="30" Visible="false">
                                        <ItemTemplate>
                                            <asp:Label ID="lblFlatId" Text='<%# Bind("flat_id") %>' runat="server" />
                                        </ItemTemplate>
                                    </asp:TemplateField>

                                    <asp:TemplateField HeaderText="Building Name" ItemStyle-Width="100">
                                        <ItemTemplate>
                                            <asp:Label ID="build_id" runat="server" Text='<%# Bind("build_name") %>' />
                                        </ItemTemplate>
                                    </asp:TemplateField>

                                    <asp:TemplateField HeaderText="Unit" ItemStyle-Width="100">
                                        <ItemTemplate>
                                            <asp:Label ID="unit" runat="server" Text='<%# Bind("unit") %>' />
                                        </ItemTemplate>
                                    </asp:TemplateField>

                                    <asp:TemplateField HeaderText="Type" ItemStyle-Width="100">
                                        <ItemTemplate>
                                            <asp:Label ID="type" runat="server" Text='<%# Bind("p_type_name") %>' />
                                        </ItemTemplate>
                                    </asp:TemplateField>

                                    <asp:TemplateField HeaderText="Query" ItemStyle-Width="250">
                                        <ItemTemplate>
                                            <asp:Label ID="query" runat="server" Text='<%# Bind("query") %>' />
                                        </ItemTemplate>
                                    </asp:TemplateField>

                                    <asp:TemplateField HeaderText="Requested Service Date" ItemStyle-Width="100">
                                        <ItemTemplate>
                                            <asp:Label ID="reqServiceDate" runat="server" Text='<%# Bind("req_service_date", "{0:yyyy-MM-dd}") %>' />
                                        </ItemTemplate>
                                    </asp:TemplateField>

                                    <%--                                    <asp:TemplateField HeaderText="Requested Service Date" ItemStyle-Width="100" Visible="false">
                                        <ItemTemplate>
                                            <asp:Label ID="reqServicedfdfDate" runat="server" Text='<%# Eval("owner_id") %>' />
                                        </ItemTemplate>
                                    </asp:TemplateField>

                                    <asp:TemplateField>
                                        <ItemTemplate>
                                            <asp:Label ID="hfOwnerId" runat="server" Value='<%# Eval("owner_id") %>'></asp:Label>
                                        </ItemTemplate>
                                    </asp:TemplateField>--%>

                                    <asp:TemplateField HeaderText="Status" ItemStyle-Width="100">
                                        <ItemTemplate>
                                            <asp:DropDownList
                                                ID="ddlStatus"
                                                runat="server"
                                                AutoPostBack="true"
                                                OnSelectedIndexChanged="ddlStatus_SelectedIndexChanged">
                                                <asp:ListItem Text="Select Status" Value="" />
                                                <asp:ListItem Text="New" Value="1" />
                                                <asp:ListItem Text="In-Progress" Value="2" />
                                                <asp:ListItem Text="On-Hold" Value="3" />
                                                <asp:ListItem Text="Closed" Value="4" />
                                            </asp:DropDownList>
                                        </ItemTemplate>
                                    </asp:TemplateField>

                                    <asp:TemplateField HeaderText="Comments" ItemStyle-Width="30">
                                        <ItemTemplate>
                                            <asp:Button
                                                ID="btnComments"
                                                runat="server"
                                                Text="View"
                                                CssClass="btn btn-info btn-sm"
                                                CommandName="ShowComments"
                                                CommandArgument='<%# Eval("helpdesk_id") + "|" + Eval("flat_id") %>' />
                                        </ItemTemplate>
                                    </asp:TemplateField>

                                    <asp:TemplateField HeaderText="Urgency" ItemStyle-Width="30">
                                        <ItemTemplate>
                                            <asp:Label ID="urgency" runat="server" Text='<%# (Eval("urgency").ToString() == "0" ? "Minor" : "Urgent") %>' />
                                        </ItemTemplate>
                                    </asp:TemplateField>


                                    <asp:TemplateField HeaderText="View Image" ItemStyle-Width="80">
                                        <ItemTemplate>
                                            <asp:Button
                                                ID="btnViewImage"
                                                runat="server"
                                                Text="View Image"
                                                CssClass="btn btn-primary btn-sm"
                                                CommandName="ShowImage"
                                                CommandArgument='<%# Eval("helpdesk_id") %>' />
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                </Columns>
                            </asp:GridView>
                        </div>
                    </div>
                </div>
            </ContentTemplate>
            <Triggers>
                <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
            </Triggers>

        </asp:UpdatePanel>


    </div>

    <!-- Helpdesk Comments Modal -->
    <div class="modal fade" id="commentsModal" tabindex="-1" role="dialog" aria-labelledby="commentsModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-lg" role="document">
            <div class="modal-content">

                <div class="modal-header">
                    <h5 class="modal-title" id="commentsModalLabel">Helpdesk Comments</h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>

                <asp:UpdatePanel ID="temp" runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <div class="modal-body d-flex flex-column" style="max-height: 500px;">

                            <!-- Hidden Field -->
                            <asp:HiddenField ID="hfHelpdeskId" runat="server" />
                            <asp:HiddenField ID="hfFlatId" runat="server" />
                            <!-- Chat container, scrollable -->
                            <div id="chatContainer" class="flex-grow-1 mb-3"
                                style="overflow-y: auto; background: #f8f9fa; padding: 10px; border: 1px solid #ddd; border-radius: 5px; height: 300px;">
                                <asp:Repeater ID="rptComments" runat="server">
                                    <ItemTemplate>
                                        <div class='<%# Eval("type").ToString() != "owner" && Eval("type").ToString() !="member" ? "chat-bubble admin" : "chat-bubble user" %>'>
                                            <div class="message-content">
                                                <div class="message-author">
                                                    <%# Eval("type").ToString() != "owner" && Eval("type").ToString() !="member"
                                                      ? (Eval("name").ToString().Contains("(admin)") ? Eval("name").ToString() : Eval("name").ToString())
                                                      : Eval("name").ToString() %>
                                                </div>
                                                <div class="message-text"><%# Eval("description") %></div>
                                                <div class="message-time"><%# Convert.ToDateTime(Eval("datetime")).ToString("MMM dd yyyy h:mmtt") %></div>
                                            </div>
                                        </div>
                                    </ItemTemplate>





                                </asp:Repeater>
                            </div>

                            <asp:Label ID="lblNoComments" runat="server" CssClass="text-muted" Visible="false" Text="No comments available." />

                            <!-- Reply input area with emoji picker & image upload -->
                            <div class="chat-input">
                                <label for="txtReply"><strong>Write a reply</strong></label>
                                <asp:TextBox ID="txtReply" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="3" placeholder="Type your reply here..." MaxLength="500" />




                                <!-- Send button -->
                                <asp:Button ID="btnReply" runat="server" Text="Send" CssClass="btn btn-primary mt-2" OnClick="btnReply_Click" />


                            </div>

                        </div>
                    </ContentTemplate>
                </asp:UpdatePanel>

                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                </div>

            </div>
        </div>
    </div>

    <div class="modal fade" id="imageModal" tabindex="-1" role="dialog" aria-labelledby="imageModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-lg" role="document">
            <div class="modal-content">
                <div class="modal-header bg-primary text-white">
                    <h5 class="modal-title" id="imageModalLabel">Helpdesk Images</h5>
                    <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>

                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <div class="modal-body">
                            <asp:Panel ID="pnlCarousel" runat="server"></asp:Panel>
                        </div>
                    </ContentTemplate>
                    <Triggers>
                        <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                    </Triggers>
                </asp:UpdatePanel>
            </div>
        </div>
    </div>
            <asp:Label ID="flat_id" runat="server" Visible="false"></asp:Label>


    <%--    <!-- ✅ Bootstrap 4 Modal -->
    <div class="modal fade" id="imageModal" tabindex="-1" role="dialog" aria-labelledby="imageModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-lg" role="document">
            <div class="modal-content">
                <div class="modal-header bg-primary text-white">
                    <h5 class="modal-title" id="imageModalLabel">Helpdesk Image</h5>
                    <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>


                        <div class="modal-body text-center">
                            <asp:Image ID="imgHelpdesk" runat="server" style="width:500px;" CssClass="img-fluid rounded shadow" AlternateText="No image available" />
                        </div>
                    </ContentTemplate>
                    <Triggers>
                        <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                    </Triggers>
                </asp:UpdatePanel>
            </div>
        </div>
    </div>--%>

<%--    <link href="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/css/bootstrap.min.css" rel="stylesheet" />
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/js/bootstrap.bundle.min.js"></script>--%>

    <script>
        function openModal() {
            $('#commentsModal').modal('show');
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



        document.addEventListener("DOMContentLoaded", function () {
            const txtReply = document.getElementById('<%= txtReply.ClientID %>');
            const btnReply = document.getElementById('<%= btnReply.ClientID %>');
            const chatContainer = document.getElementById('chatContainer');
            const emojiBtn = document.getElementById('emojiBtn');
            const imgBtn = document.getElementById('imgBtn');
            const imgUpload = document.getElementById('imgUpload');

            // Send message on Enter (Shift + Enter for newline)
            txtReply.addEventListener('keydown', function (e) {
                if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault();
                    btnReply.click(); // Trigger the server button click to submit
                }
            });

            // Emoji insertion (simple emoji picker)
            emojiBtn.addEventListener('click', function () {
                // Simple prompt for emoji selection (can be replaced with a library)
                const emoji = prompt('Enter emoji to insert (e.g. 😊, 👍, ❤️):');
                if (emoji) {
                    insertAtCursor(txtReply, emoji);
                }
            });

            // Image upload button triggers file input
            imgBtn.addEventListener('click', function () {
                imgUpload.click();
            });

            // When image selected, upload or preview (implement your image upload logic here)
            imgUpload.addEventListener('change', function () {
                const file = this.files[0];
                if (file && file.type.startsWith('image/')) {
                    // For demo: Insert image preview tag or filename in textarea
                    // You can replace this with actual upload logic if needed
                    insertAtCursor(txtReply, `[Image: ${file.name}]`);
                }
                this.value = ''; // Reset input
            });

            // Auto scroll chat container to bottom
            function scrollToBottom() {
                chatContainer.scrollTop = chatContainer.scrollHeight;
            }

            // Scroll to bottom when modal is shown or after reply submit
            $('#commentsModal').on('shown.bs.modal', function () {
                scrollToBottom();
                txtReply.focus();
            });

            // Optionally, call scrollToBottom after UpdatePanel partial postback or page load too
            // For ASP.NET AJAX UpdatePanel, hook into endRequest:
            if (Sys && Sys.WebForms && Sys.WebForms.PageRequestManager) {
                Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
                    scrollToBottom();
                    txtReply.focus();
                });
            }

            // Helper function to insert text at cursor position in textarea
            function insertAtCursor(myField, myValue) {
                if (document.selection) {
                    // IE support
                    myField.focus();
                    var sel = document.selection.createRange();
                    sel.text = myValue;
                } else if (myField.selectionStart || myField.selectionStart === 0) {
                    // Others
                    let startPos = myField.selectionStart;
                    let endPos = myField.selectionEnd;
                    let scrollTop = myField.scrollTop;
                    myField.value = myField.value.substring(0, startPos) + myValue + myField.value.substring(endPos, myField.value.length);
                    myField.focus();
                    myField.selectionStart = startPos + myValue.length;
                    myField.selectionEnd = startPos + myValue.length;
                    myField.scrollTop = scrollTop;
                } else {
                    myField.value += myValue;
                    myField.focus();
                }
            }
        });


        function scrollToBottom() {
            var chatContainer = document.getElementById("chatContainer");
            if (chatContainer) {
                chatContainer.scrollTo({
                    top: chatContainer.scrollHeight,
                    behavior: "smooth"
                });
            }
        }

        // Call this function every time modal updates
        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
            scrollToBottom();
        });

    </script>

</asp:Content>
