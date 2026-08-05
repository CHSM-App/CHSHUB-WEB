<%@ Page Language="C#" AutoEventWireup="true" Async="true" CodeBehind="Vote.aspx.cs" Inherits="Society.Vote" MasterPageFile="~/Site.Master" %>


<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="ajaxToolkit" %>
<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">

    <link href="https://fonts.googleapis.com/css2?family=Roboto&display=swap" rel="stylesheet" />
    <style>
        .poll-container {
            max-width: 600px;
            margin: 40px auto;
            padding: 30px;
            background-color: #fff;
            border-radius: 10px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }

            .poll-container h2 {
                margin-bottom: 20px;
            }

            .poll-container input[type="text"],
            .poll-container textarea,
            .poll-container input[type="date"],
            .poll-container select {
                width: 100%;
                padding: 10px;
                margin-bottom: 15px;
                border: 1px solid #ccc;
                border-radius: 6px;
            }

        .poll-options {
            margin-bottom: 15px;
        }

        .poll-option-row {
            display: flex;
            align-items: center;
            margin-bottom: 10px;
        }

            .poll-option-row input {
                flex: 1;
            }

        .remove-btn {
            margin-left: 10px;
            color: red;
            cursor: pointer;
        }

        .add-btn {
            display: inline-block;
            background-color: #00bfff;
            color: #fff;
            padding: 10px 20px;
            border-radius: 20px;
            cursor: pointer;
            border: none;
            margin-bottom: 20px;
        }

        .settings {
            margin-top: 20px;
        }

            .settings label {
                display: inline-block;
                margin-right: 20px;
            }

        .masonry-container {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 16px;
            padding: 16px;
        }

        .masonry-column {
            display: flex;
            flex-direction: column;
            gap: 16px;
        }

        .poll-card {
            box-shadow: rgba(0, 0, 0, 0.24) 0px 3px 8px;
            /*  box-shadow: rgba(0, 0, 0, 0.15) 1.95px 1.95px 2.6px;*/
            background: white;
            border: 1px solid rgba(0,0,0,0.1);
            border-radius: 12px;
            padding: 16px;
            position: relative;
            transition: all 0.3s ease;
            cursor: pointer;
            text-align: left;
            min-height: 120px;
            transition: transform 0.3s ease, height 0.3s ease;
        }

        .custom-card {
            border: 1px solid #070707 !important;
            border-radius: 8px;
        }

        .poll-card:hover {
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
            transform: translateY(-2px);
        }

        .delete-btn {
            position: absolute;
            top: 8px;
            right: 8px;
            width: 24px;
            height: 24px;
            background-color: #ef4444;
            color: white;
            border: none;
            border-radius: 50%;
            cursor: pointer;
            opacity: 0;
            transition: opacity 0.2s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 12px;
        }

        .poll-card:hover .delete-btn {
            opacity: 1;
        }

        .delete-btn:hover {
            background-color: #dc2626;
        }

        .poll-title {
            font-size: 20px;
            font-weight: 600;
            color: #374151;
            margin-bottom: 12px;
        }

        .poll-question {
            font-size: 14px;
            color: #6b7280;
            line-height: 1.6;
            margin-bottom: 12px;
        }

        .option {
            background: #dcdcdc;
            border-radius: 8px;
            padding: 10px;
            margin-bottom: 15px;
            cursor: pointer;
            transition: background 0.2s ease;
        }

            .option:hover {
                background: #919191;
            }

            .option.voted {
                background-color: #c8e6c9;
                border: 2px solid #4caf50;
            }

        .result-row {
            display: none;
            align-items: center;
            margin-top: 8px;
            gap: 8px;
        }

        .bar-container {
            flex: 1;
            background: #c8c8c8;
            height: 6px;
            border-radius: 3px;
            overflow: hidden;
        }

        .bar {
            height: 100%;
            background: #38bdf8;
            width: 0%;
            transition: width 1s ease;
        }

        .percentage {
            min-width: 35px;
            font-size: 14px;
            text-align: right;
        }

        .poll-footer {
            font-size: 12px;
            color: #9ca3af;
            margin-top: 12px;
            padding-top: 8px;
            border-top: 1px solid #e5e7eb;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .total-votes {
            color: #007bff;
            font-weight: bold;
            cursor: pointer;
        }

        .expiry-date {
            color: #777;
        }

        .poll-detail {
            border-bottom: 1px solid #e0e0e0;
            padding-bottom: 15px;
        }

        .vote-details-body {
            max-height: 450px;
            overflow-y: auto;
            padding: 20px;
        }

        .poll-section {
            margin-bottom: 20px;
        }

        .question-title {
            font-weight: 600;
            color: #007bff;
            margin-bottom: 15px;
        }

        .option-block {
            background-color: #f9f9f9;
            border: 1px solid #ddd;
            border-radius: 6px;
            padding: 10px 15px;
            margin-bottom: 12px;
        }

        .option-title {
            font-weight: 500;
            color: #333;
            margin-bottom: 8px;
        }

            .option-title span {
                font-weight: bold;
                color: #000;
            }

        .voter-list {
            list-style: disc;
            padding-left: 20px;
            margin-bottom: 0;
        }

            .voter-list li {
                font-size: 14px;
                color: #444;
                margin-bottom: 4px;
            }

        .text-muted {
            color: #888 !important;
        }

        .poll-option-row .btn-outline-danger {
            padding: 0.375rem 0.5rem;
        }

        .poll-option-row i.fas.fa-times {
            pointer-events: none;
        }

        .settings .form-check {
            margin-bottom: 0.5rem;
        }

        .visibleTrue {
            display: block;
        }

        .visibleFalse {
            display: none;
        }

        .fab-small {
            position: fixed;
            bottom: 20px;
            right: 20px;
            border-radius: 50px;
            padding: 8px 14px;
            font-size: 14px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.3);
            z-index: 1050;
            display: flex;
            align-items: center;
        }

        @media (max-width: 768px) {
            .masonry-container {
                grid-template-columns: repeat(2, 1fr);
            }
        }

        @media (max-width: 480px) {
            .masonry-container {
                grid-template-columns: 1fr;
            }
        }
    </style>


    <div class="box box-primary">
        <div class="box-header with-border">
            <div class="box-body">
                <table width="100%">
                    <tr>
                        <th width="100%">
                            <h1 class=" font-weight-bold " style="color: #012970;">Polls</h1>
                        </th>
                    </tr>
                </table>
                <asp:UpdatePanel runat="server" UpdateMode="Conditional" ID="upPolls">
                    <ContentTemplate>

                        <div class="form-group">
                            <div class="row">
                                <div class="col-12">
                                    <div class="top-row d-flex align-items-center">
                                        <div class="search-container">

                                            <asp:TextBox
                                                ID="txt_search"
                                                CssClass="aspNetTextBox"
                                                placeHolder="Search here"
                                                runat="server"
                                                TextMode="Search"
                                                AutoPostBack="true"  autocomplete="off"
 onkeyup="filterTable()"/>

                                            <ajaxToolkit:CalendarExtender
                                                ID="CalendarExtender1"
                                                runat="server"
                                                TargetControlID="txt_search"
                                                PopupButtonID="btn_calendar"
                                                Format="yyyy-MM-dd" />

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
                                                    runat="server"  onclick="filterTable()">
                                                    <span class="material-symbols-outlined">search</span>
                                                </button>
                                            </div>
                                        </div>

                                        &nbsp;&nbsp;
                                <button type="button" class="w-90 btn btn-primary" data-toggle="modal" data-target="#createPollModal"><i class="fas fa-plus mr-1"></i>Create Poll</button>

                                    </div>
                                </div>
                            </div>
                        </div>

                        <asp:HiddenField runat="server" ID="optionID" />
                        <div class="masonry-container g-Table" id="masonryContainer">

                            <asp:Repeater ID="Repeater1" runat="server" OnItemCommand="Repeater1_ItemCommand" OnItemDataBound="Repeater1_ItemDataBound">
                                <ItemTemplate>
                                    <div class="poll-card"
                                        data-has-voted='<%# Eval("HasVoted") %>'
                                        data-voted-option-id='<%# Eval("VotedOptionIds") %>'
                                        data-column-index='<%# Container.ItemIndex %>'>
                                        <asp:LinkButton runat="server" ID="btnDelete" CommandName="DeletePoll"
                                            CommandArgument='<%# Eval("PollId") %>' CssClass="delete-btn" ToolTip="Delete Poll">
                                            <i class="fas fa-times"></i>
                                        </asp:LinkButton>
                                        <div class="poll-title"><%# Eval("Topic") %></div>
                                        <div class="poll-question"><%# Eval("Description") %></div>
                                        <asp:HiddenField runat="server" ID="PollId" Value='<%# Eval("PollId") %>' />
                                        <asp:PlaceHolder runat="server" ID="optionContainer"></asp:PlaceHolder>
                                        <div class="poll-footer">
                                            <div>
                                                <asp:LinkButton CssClass="btnVote visibleFalse" runat="server" ID="LinkButton1" CommandName="ShowVotes"
                                                    CommandArgument='<%# Eval("PollId") %>' ToolTip="Show Poll">
                                                <div class="total-votes">0 votes</div>
                                                </asp:LinkButton>
                                            </div>
                                            <div class="expiry-date">
                                                Expires: <%# Eval("ExpiryDate", "{0:dd MMM yyyy}") %>
                                            </div>
                                        </div>
                                    </div>
                                </ItemTemplate>
                            </asp:Repeater>

                        </div>
                    </ContentTemplate>
                    <Triggers>
                        <asp:AsyncPostBackTrigger ControlID="btnStartPoll" EventName="Click" />
                        <asp:AsyncPostBackTrigger ControlID="Repeater1" EventName="ItemCommand" />
                    </Triggers>
                </asp:UpdatePanel>

                <!-- Bootstrap Modal -->
                <div class="modal fade" id="createPollModal" tabindex="-1" role="dialog" aria-labelledby="createPollModalLabel" aria-hidden="true">
                    <div class="modal-dialog modal-lg" role="document">
                        <div class="modal-content shadow-lg">
                            <div class="modal-header bg-primary text-white">
                                <h5 class="modal-title mb-0" id="createPollModalLabel">
                                    <i class="fas fa-poll mr-2"></i>Create a New Poll
                                </h5>
                                <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close" style="opacity: 1;">
                                    <span aria-hidden="true">&times;</span>
                                </button>
                            </div>
                            <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                                <ContentTemplate>

                                    <div class="modal-body p-4">
                                        <div class="form-group">
                                            <asp:TextBox ID="txtTopic" runat="server" CssClass="form-control" Placeholder="Enter Poll Topic"></asp:TextBox>
                                        </div>
                                        <div class="form-group">
                                            <asp:TextBox ID="txtDescription" runat="server" CssClass="form-control" TextMode="MultiLine"
                                                Placeholder="Describe the poll in detail" Rows="3"></asp:TextBox>
                                        </div>
                                        <label class="font-weight-bold">Options</label>
                                        <div class="poll-options mb-3" id="pollOptionsContainer">
                                            <div class="poll-option-row d-flex align-items-center mb-2">
                                                <input type="text" name="option" placeholder="Option 1" class="form-control option-input mr-2" />
                                                <button type="button" class="btn btn-outline-danger btn-sm" onclick="removeOption(this)">
                                                    <i class="fas fa-times"></i>
                                                </button>
                                            </div>
                                            <div class="poll-option-row d-flex align-items-center mb-2">
                                                <input type="text" name="option" placeholder="Option 2" class="form-control option-input mr-2" />
                                                <button type="button" class="btn btn-outline-danger btn-sm" onclick="removeOption(this)">
                                                    <i class="fas fa-times"></i>
                                                </button>
                                            </div>
                                        </div>
                                        <button type="button" class="btn btn-outline-secondary btn-sm mb-4" onclick="addOption()">
                                            <i class="fas fa-plus"></i>Add More Options
                                        </button>
                                        <div class="form-group">
                                            <label class="font-weight-bold">Poll Expiry Date</label>
                                            <asp:TextBox ID="txtExpiryDate" runat="server" CssClass="form-control" TextMode="Date"></asp:TextBox>
                                        </div>
                                        <div class="settings mb-4">
                                            <label class="font-weight-bold">Voting Settings</label>
                                            <div class="form-check">
                                                <asp:CheckBox ID="chkMultipleVotes" runat="server" CssClass="form-check-input" />
                                                <label class="form-check-label" for="chkMultipleVotes">Allow Multiple Votes</label>
                                            </div>
                                            <div class="form-check">
                                                <asp:CheckBox ID="chkOneVotePerUnit" runat="server" CssClass="form-check-input" />
                                                <label class="form-check-label" for="chkOneVotePerUnit">One Vote per Unit</label>
                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <label class="font-weight-bold">Target Audience</label>
                                            <asp:DropDownList ID="ddlAudience" runat="server" CssClass="form-control">
                                                <asp:ListItem Text="All Members" Value="1" />
                                                <asp:ListItem Text="Association Committee" Value="2" />
                                                <asp:ListItem Text="Owners Only" Value="3" />
                                                <asp:ListItem Text="Tenants Only" Value="4" />
                                            </asp:DropDownList>
                                        </div>
                                    </div>

                                </ContentTemplate>
                            </asp:UpdatePanel>

                            <div class="modal-footer">
                                <div class="text-right">
                                    <asp:Button ID="btnStartPoll" runat="server" Text="Start Poll" CssClass="btn btn-success px-4" OnClick="btnStartPoll_Click" />
                                </div>

                            </div>


                        </div>
                    </div>
                </div>

                <!-- Poll Detail Modal -->
                <div class="modal fade" id="voteDetailModal" tabindex="-1" role="dialog" aria-labelledby="voteDetailModalLabel" aria-hidden="true">
                    <div class="modal-dialog modal-dialog-centered modal-md" role="document">
                        <div class="modal-content rounded-3 overflow-hidden">
                            <div class="modal-header bg-info text-white">
                                <h5 class="modal-title">Poll Vote Details</h5>
                                <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close">
                                    <span>&times;</span>
                                </button>
                            </div>
                            <div class="modal-body vote-details-body p-3 bg-light">
                                <asp:Repeater ID="rptPolls" runat="server">
                                    <ItemTemplate>
                                        <div class="bg-white shadow-sm rounded p-3 mb-4 border-left border-primary border-4">
                                            <h5 class="text-primary font-weight-bold mb-3">
                                                <i class="fas fa-poll mr-2"></i>Poll: <%# Eval("Topic") %>
                                            </h5>
                                            <asp:Repeater ID="rptOptions" runat="server" DataSource='<%# Eval("Options") %>'>
                                                <ItemTemplate>
                                                    <div class="mb-3 p-3 border rounded bg-light">
                                                        <div class="d-flex justify-content-between align-items-center mb-2">
                                                            <span class="font-weight-bold text-dark">
                                                                <i class="fas fa-check-circle text-success mr-2"></i>
                                                                Option: <%# Eval("Option") %>
                                                            </span>
                                                            <span class="badge badge-pill badge-primary">
                                                                <%# ((List<string>)Eval("Users")).Count %> Vote(s)
                                                            </span>
                                                        </div>
                                                        <div class="pl-2 text-muted" style="line-height: 1.6;">
                                                            <%# string.Join("<br/>", ((List<string>)Eval("Users"))) %>
                                                        </div>
                                                    </div>
                                                </ItemTemplate>
                                            </asp:Repeater>
                                        </div>
                                    </ItemTemplate>
                                </asp:Repeater>
                            </div>
                        </div>
                    </div>
                </div>


            </div>
        </div>
    </div>

<%--    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css" />
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
    <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.5.2/dist/js/bootstrap.bundle.min.js"></script>--%>

    <script>

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

        let voted = false;
        let votes = [];

        let showResultsBeforeVote = true;

        function calculateCardHeight(card) {
            const tempDiv = document.createElement('div');
            tempDiv.style.position = 'absolute';
            tempDiv.style.visibility = 'hidden';
            tempDiv.style.width = '250px';
            tempDiv.style.padding = '16px';
            tempDiv.className = 'poll-card';
            tempDiv.innerHTML = card.innerHTML;
            document.body.appendChild(tempDiv);
            const height = Math.max(tempDiv.offsetHeight, 120);
            document.body.removeChild(tempDiv);
            return height;
        }

        function getColumnCount() {
            const width = window.innerWidth;
            if (width <= 480) return 1;
            if (width <= 768) return 2;
            return 4;
        }

        function distributeCards() {
            const container = document.getElementById('masonryContainer');
            const cards = Array.from(container.querySelectorAll('.poll-card'));
            const columnCount = getColumnCount();

            // Prepare columns array and heights tracker
            const columns = Array.from({ length: columnCount }, () => []);
            const columnHeights = new Array(columnCount).fill(0);

            // Distribute each card to the column with the smallest current height
            cards.forEach(card => {
                const cardHeight = calculateCardHeight(card);

                // Find column index with smallest height
                const shortestColumnIndex = columnHeights.indexOf(Math.min(...columnHeights));

                // Place card into that column
                columns[shortestColumnIndex].push(card);

                // Update that column's total height
                columnHeights[shortestColumnIndex] += cardHeight;
            });

            // Clear container and rebuild DOM with new column structure
            container.innerHTML = '';
            columns.forEach(column => {
                const columnDiv = document.createElement('div');
                columnDiv.className = 'masonry-column';
                column.forEach(card => columnDiv.appendChild(card));
                container.appendChild(columnDiv);
            });
        }


        document.addEventListener("DOMContentLoaded", function () {
            distributeCards();
            window.addEventListener('resize', distributeCards);

            document.querySelectorAll(".poll-card").forEach(card => {
                let hasVoted = card.getAttribute("data-has-voted") === "1";
                let options = card.querySelectorAll(".option");
                let votes = Array.from(options).map(opt => parseInt(opt.getAttribute("data-votes")));
                let total = votes.reduce((a, b) => a + b, 0);
                let voteButton = card.querySelector(".btnVote");

                if (voteButton) {
                    if (hasVoted) {
                        voteButton.classList.add("visibleTrue");
                        voteButton.classList.remove("visibleFalse");
                    } else {
                        voteButton.classList.add("visibleFalse");
                        voteButton.classList.remove("visibleTrue");
                    }
                }

                if (hasVoted && total > 0) {
                    card.dataset.voted = "true";
                    card.querySelector(".total-votes").innerText = total + " votes";
                    options.forEach((opt, i) => {
                        const percent = ((votes[i] / total) * 100).toFixed(0);
                        const resultRow = opt.querySelector(".result-row");
                        const percentageText = opt.querySelector(".percentage");
                        const bar = opt.querySelector(".bar");
                        resultRow.style.display = "flex";
                        percentageText.innerText = percent + "%";
                        bar.style.width = percent + "%";
                    });
                } else {
                    options.forEach(opt => {
                        const resultRow = opt.querySelector(".result-row");
                        if (resultRow) resultRow.style.display = "none";
                    });
                }

                let votedOptionIds = card.getAttribute("data-voted-option-id");
                if (hasVoted && votedOptionIds && votedOptionIds !== "0") {
                    let votedIdsArray = votedOptionIds.split(",").map(id => id.trim());
                    options.forEach(opt => {
                        let optId = opt.getAttribute("data-option-id");
                        if (votedIdsArray.includes(optId)) {
                            opt.classList.add("voted");
                        }
                    });
                }
            });
        });

        function sendVoteToServer(OneVotePerUnit, AllowMultipleVotes, userId, pollId, optionId, SocietyID, UserType) {
            fetch('VoteService.asmx/SaveVote', {
                method: 'POST',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    userId: userId,
                    pollId: pollId,
                    optionId: optionId,
                    userType: UserType,
                    SocietyID: SocietyID,
                    AllowMultipleVotes: AllowMultipleVotes,
                    OneVotePerUnit: OneVotePerUnit
                })
            })
                .then(response => response.json())
                .then(data => {
                    console.log("Vote saved:", data);
                })
                .catch(error => {
                    console.error("Error saving vote:", error);
                });
        }

        function showVoteDetails(pollId) {
            fetch('VoteService.asmx/GetVoteDetails', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ pollId: pollId })
            })
                .then(response => response.json())
                .then(data => {
                    const d = data.d;
                    let html = `<h5>${d.Topic}</h5><p>${d.Description}</p>`;
                    d.Options.forEach(opt => {
                        html += `<div style="margin-bottom:20px;">
                            <strong>${opt.OptionText}</strong>
                            <ul>`;
                        if (opt.Voters.length > 0) {
                            opt.Voters.forEach(user => {
                                html += `<li>${user}</li>`;
                            });
                        } else {
                            html += `<li><em>No votes yet</em></li>`;
                        }
                        html += `</ul></div>`;
                    });
                    document.getElementById("voteDetailContent").innerHTML = html;
                    $('#voteDetailModal').modal('show');
                })
                .catch(err => {
                    console.error("Failed to load vote details", err);
                });
        }

        let optionCount = 3;

        function addOption() {
            const container = document.getElementById("pollOptionsContainer");
            const count = container.getElementsByClassName("poll-option-row").length + 1;
            const div = document.createElement("div");
            div.className = "poll-option-row d-flex align-items-center mb-2";
            div.innerHTML = `
                <input type="text" name="option" placeholder="Option ${count}" class="form-control option-input mr-2" />
                <button type="button" class="btn btn-outline-danger btn-sm" onclick="removeOption(this)">
                    <i class="fas fa-times"></i>
                </button>
            `;
            container.appendChild(div);
        }

        function removeOption(el) {
            const row = el.parentElement;
            row.remove();
        }

        function vote(hasVoted, OneVotePerUnit, AllowMultipleVotes, PollId, OptionId, index, UserID, SocietyID, UserType, pollContainer) {
            const options = pollContainer.querySelectorAll(".option");

            // Prevent multiple votes on same option
            const clickedOption = options[index];
            if (clickedOption.classList.contains("voted")) return; // Already voted this option

            // Prevent multiple votes if not allowed
            if (pollContainer.dataset.voted === "true" && !AllowMultipleVotes) return;

            // If multiple votes are allowed, mark this option only
            clickedOption.classList.add("voted");

            // If only one vote allowed, mark the whole poll as voted
            if (!AllowMultipleVotes) pollContainer.dataset.voted = "true";

            // Update vote counts
            let votes = Array.from(options).map(opt => parseInt(opt.getAttribute("data-votes")) || 0);
            votes[index] += 1;
            const total = votes.reduce((a, b) => a + b, 0);
            pollContainer.querySelector(".total-votes").innerText = total + " votes";

            // Update result bars
            options.forEach((opt, i) => {
                const percent = ((votes[i] / total) * 100).toFixed(0);
                const resultRow = opt.querySelector(".result-row");
                const percentageText = opt.querySelector(".percentage");
                const bar = opt.querySelector(".bar");
                opt.setAttribute("data-votes", votes[i]);
                resultRow.style.display = "flex";
                percentageText.innerText = percent + "%";
                setTimeout(() => {
                    bar.style.width = percent + "%";
                }, 100);
            });
            
            // Send vote to server
            sendVoteToServer(OneVotePerUnit, AllowMultipleVotes, UserID, PollId, OptionId, SocietyID, UserType);
        }

    </script>
</asp:Content>
