<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="YourNamespace.Default" %>

<!DOCTYPE html>
<html>
<head>
    <title>Draggable Repeater</title>
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://code.jquery.com/ui/1.13.2/jquery-ui.min.js"></script>
    <link rel="stylesheet" href="https://code.jquery.com/ui/1.13.2/themes/base/jquery-ui.css">
    <style>
        .repeater-container {
            width: 100%;
            max-width: 800px;
            margin: 20px auto;
        }
        .repeater-item {
            padding: 15px;
            margin: 5px 0;
            background: #f5f5f5;
            border: 1px solid #ddd;
            cursor: move;
            border-radius: 4px;
            transition: background-color 0.2s;
        }
        .repeater-item:hover {
            background: #e8e8e8;
        }
        .ui-sortable-helper {
            background: #fff;
            box-shadow: 0 5px 15px rgba(0,0,0,0.3);
        }
        .ui-sortable-placeholder {
            background: #d4edda;
            border: 2px dashed #28a745;
            visibility: visible !important;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <asp:ScriptManager ID="ScriptManager1" runat="server" EnablePageMethods="true" />
        
        <div class="repeater-container">
            <div id="sortableRepeater">
                <asp:Repeater ID="rptItems" runat="server">
                    <ItemTemplate>
                        <div class="repeater-item" data-id='<%# Eval("Id") %>'>
                            <strong><%# Eval("Title") %></strong>
                            <p><%# Eval("Description") %></p>
                            <small>Sequence: <%# Eval("SequenceOrder") %></small>
                        </div>
                    </ItemTemplate>
                </asp:Repeater>
            </div>
        </div>

        <script type="text/javascript">
            $(document).ready(function () {
                $("#sortableRepeater").sortable({
                    handle: ".repeater-item",
                    placeholder: "ui-sortable-placeholder",
                    update: function (event, ui) {
                        var items = [];
                        
                        // Get all items in new order
                        $("#sortableRepeater .repeater-item").each(function (index) {
                            items.push({
                                Id: $(this).data("id"),
                                SequenceOrder: index + 1
                            });
                        });

                        // Call server-side method to update database
                        $.ajax({
                            type: "POST",
                            url: "Default.aspx/UpdateSequence",
                            data: JSON.stringify({ items: items }),
                            contentType: "application/json; charset=utf-8",
                            dataType: "json",
                            success: function (response) {
                                if (response.d) {
                                    console.log("Sequence updated successfully");
                                    // Optional: Show a brief success message
                                    // alert("Order updated!");
                                } else {
                                    alert("Failed to update sequence");
                                }
                            },
                            error: function (xhr, status, error) {
                                console.error("Error updating sequence:", error);
                                alert("Error updating sequence. Please try again.");
                            }
                        });
                    }
                });
            });
        </script>
    </form>
</body>
</html>