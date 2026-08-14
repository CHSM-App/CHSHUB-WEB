<%@ Page Language="C#" Async="true" AutoEventWireup="true" CodeBehind="new_society.aspx.cs" ValidateRequest="false" Inherits="Society2024.society1"  %>
<!DOCTYPE html>
<html>
<head>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <link href="https://cdn.jsdelivr.net/npm/summernote@0.8.18/dist/summernote-bs4.min.css" rel="stylesheet">
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/summernote@0.8.18/dist/summernote-bs4.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
        <script src="https://cdn.jsdelivr.net/npm/tinymce@6/tinymce.min.js"></script>



    <style>
        :root {
            --primary-blue: #2C5F9E;
            --light-blue: #4A90E2;
            --success-green: #28a745;
        }
        .wizard-container { background: #fff; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .wizard-header { background: linear-gradient(135deg, var(--primary-blue) 0%, var(--light-blue) 100%); color: white; padding: 20px; border-radius: 8px 8px 0 0; }
        .wizard-steps { display: flex; justify-content: space-between; padding: 30px 20px; background: #f8f9fa; border-bottom: 2px solid #e9ecef; }
        .wizard-step { flex: 1; text-align: center; position: relative; }
        .wizard-step:not(:last-child)::after { content: ''; position: absolute; top: 20px; left: 60%; width: 80%; height: 2px; background: #dee2e6; z-index: 0; }
        .wizard-step.active:not(:last-child)::after, .wizard-step.completed:not(:last-child)::after { background: var(--light-blue); }
        .step-circle { width: 40px; height: 40px; border-radius: 50%; background: #fff; border: 3px solid #dee2e6; display: inline-flex; align-items: center; justify-content: center; font-weight: bold; color: #6c757d; position: relative; z-index: 1; transition: all 0.3s; }
        .wizard-step.active .step-circle { background: var(--light-blue); border-color: var(--light-blue); color: white; transform: scale(1.1); }
        .wizard-step.completed .step-circle { background: var(--success-green); border-color: var(--success-green); color: white; }
        .step-label { display: block; margin-top: 10px; font-size: 13px; font-weight: 600; color: #6c757d; }
        .wizard-step.active .step-label { color: var(--primary-blue); }
        .wizard-step.completed .step-label { color: var(--success-green); }
        .wizard-content { padding: 30px; min-height: 400px; }
        .wizard-pane { display: none; }
        .wizard-pane.active { display: block; animation: fadeIn 0.3s; }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
        .form-label { font-weight: 600; color: #495057; margin-bottom: 8px; }
        .form-control, .form-select { border-radius: 6px; border: 1px solid #ced4da;  }
        .form-control:focus, .form-select:focus { border-color: var(--light-blue); box-shadow: 0 0 0 0.2rem rgba(74, 144, 226, 0.25); }
        .required-mark { color: #dc3545; margin-left: 3px; }
        .wizard-actions { padding: 20px 30px; background: #f8f9fa; border-top: 1px solid #dee2e6; display: flex; justify-content: space-between; border-radius: 0 0 8px 8px; }
        .btn-wizard { padding: 10px 30px; border-radius: 6px; font-weight: 600; transition: all 0.3s; }
        .btn-primary-wizard { background: var(--primary-blue); border: none; color: white; }
        .btn-primary-wizard:hover { background: var(--light-blue); transform: translateY(-2px); box-shadow: 0 4px 8px rgba(0,0,0,0.2); color: white; }
        .btn-secondary-wizard { background: #6c757d; border: none; color: white; }
        .btn-secondary-wizard:hover { background: #5a6268; color: white; }
        .section-divider { border-top: 2px solid #e9ecef; margin: 25px 0; position: relative; }
        .section-title { background: white; position: relative; top: -12px; display: inline-block; padding: 0 15px; color: var(--primary-blue); font-weight: 600; font-size: 16px; }
        .info-icon { color: var(--light-blue); margin-right: 5px; }
        .note-editor { border: 1px solid #ced4da; border-radius: 6px; }
        .is-invalid { border-color: #dc3545 !important; }
    </style>

    <style>
.note-editor .custom-control-input {
    position: static !important;
    opacity: 1 !important;
}

/* restore Bootstrap switch outside Summernote */
.custom-switch .custom-control-input {
    position: absolute !important;
    opacity: 0 !important;
}
</style>

</head>

<div class="container mt-5 mb-5">
        <form runat="server" autocomplete="off" id="myForm" class="needs-validation" novalidate>
    <asp:ScriptManager ID="ScriptManager1" runat="server" EnablePartialRendering="true"></asp:ScriptManager>
    <div class="wizard-container">
        <div class="wizard-header">
            <h3 class="mb-0"><i class="fas fa-building"></i> New Society Registration</h3>
            <p class="mb-0 mt-2">Complete all steps to register your society</p>
        </div>

        <div class="wizard-steps">
            <div class="wizard-step active" id="wizard-step-1">
                <span class="step-circle">1</span>
                <span class="step-label">Basic Info</span>
            </div>
            <div class="wizard-step" id="wizard-step-2">
                <span class="step-circle">2</span>
                <span class="step-label">Contact Details</span>
            </div>
            <div class="wizard-step" id="wizard-step-3">
                <span class="step-circle">3</span>
                <span class="step-label">Location</span>
            </div>
            <div class="wizard-step" id="wizard-step-4">
                <span class="step-circle">4</span>
                <span class="step-label">Settings</span>
            </div>
        </div>

        <asp:HiddenField ID="hdnCurrentStep" runat="server" Value="1" />
        <asp:HiddenField ID="society_master_id" runat="server" />
        <asp:HiddenField ID="user_id" runat="server" />
        <asp:HiddenField ID="society_id" runat="server" />
        <asp:HiddenField ID="hdnTermsContent" runat="server" />

        <div class="wizard-content">
            <!-- Step 1: Basic Information -->
            <div class="wizard-pane active" id="step-1">
                <h5 class="mb-4"><i class="fas fa-info-circle info-icon"></i>Basic Information</h5>
                <div class="row">
                    <div class="col-md-6 mb-3">
                        <label class="form-label">Society Name <span class="required-mark">*</span></label>
                        <asp:TextBox ID="txt_name" CssClass="form-control" runat="server" placeholder="Enter Society Name"></asp:TextBox>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="form-label">Establish Date <span class="required-mark">*</span></label>
                        <asp:TextBox ID="txt_es_date" CssClass="form-control" TextMode="Date" runat="server"></asp:TextBox>
                    </div>
                </div>
                <div class="row">
                    <div class="col-md-6 mb-3">
                        <label class="form-label">Registration No <span class="required-mark">*</span></label>
                        <asp:UpdatePanel ID="upnlRegistration" runat="server" UpdateMode="Conditional">
                            <ContentTemplate>
                                <asp:TextBox ID="txt_registration" CssClass="form-control" runat="server" AutoPostBack="true" placeholder="Enter Registration Number" OnTextChanged="txt_registration_TextChanged"></asp:TextBox>
                                <asp:Label ID="Label22" runat="server" Font-Bold="True" ForeColor="Red" CssClass="mt-1 d-block"></asp:Label>
                            </ContentTemplate>
                        </asp:UpdatePanel>
                    </div>
                </div>
                <div class="section-divider">
                    <span class="section-title">Terms & Conditions</span>
                    <asp:TextBox ID="editor1" runat="server" TextMode="MultiLine" Width="100%" Rows="10"></asp:TextBox>
                </div>

            </div>

            <!-- Step 2: Contact Information -->
            <div class="wizard-pane" id="step-2">
                <h5 class="mb-4"><i class="fas fa-address-card info-icon"></i>Contact Information</h5>
                <div class="row">
                    <div class="col-md-6 mb-3">
                        <label class="form-label">Office Address <span class="required-mark">*</span></label>
                        <asp:TextBox ID="txt_off_address1" CssClass="form-control" runat="server" placeholder="Enter Primary Address"></asp:TextBox>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="form-label">Alternate Address</label>
                        <asp:TextBox ID="txt_off_address2" CssClass="form-control" runat="server" placeholder="Enter Alternate Address"></asp:TextBox>
                    </div>
                </div>
                <div class="row">
                    <div class="col-md-6 mb-3">
                        <label class="form-label">Contact Number <span class="required-mark">*</span></label>
                        <asp:TextBox ID="txt_contact_no1" CssClass="form-control" runat="server" MaxLength="10" placeholder="Enter 10-digit Mobile Number"></asp:TextBox>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="form-label">Email ID <span class="required-mark">*</span></label>
                        <asp:TextBox ID="txt_email" CssClass="form-control" placeholder="Enter Email Address" runat="server" TextMode="Email"></asp:TextBox>
                    </div>
                </div>
            </div>

            <!-- Step 3: Location Details -->
            <div class="wizard-pane" id="step-3">
                <h5 class="mb-4"><i class="fas fa-map-marker-alt info-icon"></i>Location Details</h5>
                    <asp:UpdatePanel ID="upnlLocation" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="false">
                    <contenttemplate>
                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label class="form-label">State <span class="required-mark">*</span></label>
                                <asp:DropDownList CssClass="form-control" ID="ddl_state" OnSelectedIndexChanged="ddl_state_SelectedIndexChanged" AutoPostBack="true" runat="server"></asp:DropDownList>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">District <span class="required-mark">*</span></label>
                                <asp:DropDownList CssClass="form-control" ID="ddl_district" OnSelectedIndexChanged="ddl_district_SelectedIndexChanged" AutoPostBack="true" runat="server"></asp:DropDownList>
                            </div>
                        </div>
                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label class="form-label">Division <span class="required-mark">*</span></label>
                                <asp:DropDownList CssClass="form-control" ID="ddl_division" runat="server"></asp:DropDownList>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">City <span class="required-mark">*</span></label>
                                <asp:TextBox ID="txt_city" CssClass="form-control" runat="server" placeholder="Enter City Name"></asp:TextBox>
                            </div>
                        </div>
                    </contenttemplate>
                    <triggers>
                        <asp:AsyncPostBackTrigger ControlID="ddl_state" EventName="SelectedIndexChanged" />
                        <asp:AsyncPostBackTrigger ControlID="ddl_district" EventName="SelectedIndexChanged" />
                    </triggers>
                </asp:UpdatePanel>
                <div class="row">
                    <div class="col-md-6 mb-3">
                        <label class="form-label">Street/Home No <span class="required-mark">*</span></label>
                        <asp:TextBox ID="txt_street" CssClass="form-control" runat="server" placeholder="Enter Street/Home Number"></asp:TextBox>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="form-label">Pincode <span class="required-mark">*</span></label>
                        <asp:TextBox ID="txt_pincode" CssClass="form-control" runat="server" MaxLength="6" placeholder="Enter 6-digit PIN"></asp:TextBox>
                    </div>
                </div>
            </div>

            <!-- Step 4: Maintenance Settings -->
            <div class="wizard-pane" id="step-4">
                <h5 class="mb-4"><i class="fas fa-cog info-icon"></i>Regular Maintenance Settings</h5>
                <div class="row">
                    <div class="col-md-6 mb-3">
                        <label class="form-label">Per Sq. Feet Rate <span class="required-mark">*</span></label>
                        <asp:TextBox ID="txt_per_sqft_rate" runat="server" CssClass="form-control" placeholder="Enter rate per sq. ft."></asp:TextBox>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="form-label">2 Wheeler Rate <span class="required-mark">*</span></label>
                        <asp:TextBox ID="txt_2w_rate" runat="server" CssClass="form-control" placeholder="Enter 2 wheeler parking rate"></asp:TextBox>
                    </div>
                </div>
                <div class="row">
                    <div class="col-md-6 mb-3">
                        <label class="form-label">4 Wheeler Rate <span class="required-mark">*</span></label>
                        <asp:TextBox ID="txt_4w_rate" runat="server" CssClass="form-control" placeholder="Enter 4 wheeler parking rate"></asp:TextBox>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="form-label">Generation Day (1-31) <span class="required-mark">*</span></label>
                        <asp:TextBox ID="txt_gen_day" runat="server" CssClass="form-control" placeholder="Enter day of month" TextMode="Number"></asp:TextBox>
                    </div>
                </div>
                <div class="row align-items-center">
                    <div class="col-md-6 mb-3">
                        <label class="form-label">Due Date Period (days) <span class="required-mark">*</span></label>
                        <asp:TextBox ID="txt_due_period" runat="server" CssClass="form-control" placeholder="Enter number of days" TextMode="Number"></asp:TextBox>
                    </div>

                    <div class="custom-control custom-switch col-md-6 mb-3">
                        <input type="checkbox" class="custom-control-input" id="chk_auto_gen" runat="server">
                        <label class="custom-control-label" for="chk_auto_gen">Auto Generate Maintenance</label>
                    </div>



                </div>
            </div>
        </div>

        <!-- Wizard Actions -->
        <div class="wizard-actions">
            <div>
                <button type="button" class="btn btn-wizard btn-secondary-wizard" id="btnPrevious" onclick="previousStep()" style="display:none;">
                    <i class="fas fa-arrow-left"></i> Previous
                </button>
            </div>
            <div>
                <button type="button" class="btn btn-wizard btn-primary-wizard" id="btnNext" onclick="nextStep()">
                    Next <i class="fas fa-arrow-right"></i>
                </button>
                <asp:Button ID="btn_save" runat="server" Text="Submit Registration" CssClass="btn btn-wizard btn-primary-wizard" OnClick="btn_save_Click" OnClientClick="return prepareSubmit();" Style="display:none;" />
            </div>
        </div>
    </div>
            </form>
</div>

<script type="text/javascript">
    var currentStep = 1;
    var totalSteps = 4;



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

    $(document).ready(function () {
        // Initialize Summernote rich text editor
        $('#summernote').summernote({
            height: 200,
            toolbar: [
                ['style', ['style']],
                ['font', ['bold', 'italic', 'underline', 'clear']],
                ['fontsize', ['fontsize']],
                ['color', ['color']],
                ['para', ['ul', 'ol', 'paragraph']],
                ['table', ['table']],
                ['insert', ['link']],
                ['view', ['fullscreen', 'codeview']]
            ],
            fontSizes: ['8', '10', '12', '14', '16', '18', '20', '24', '28', '32', '36'],
            placeholder: 'Enter terms and conditions...'
        });

        // Restore step from hidden field after postback
        var savedStep = $('#<%= hdnCurrentStep.ClientID %>').val();
        if (savedStep) {
            currentStep = parseInt(savedStep);
            showStep(currentStep);
        }

        // Restore summernote content
        var savedContent = $('#<%= hdnTermsContent.ClientID %>').val();
        if (savedContent) {
            $('#summernote').summernote('code', savedContent);
        }
    });

    function showStep(step) {
        $('.wizard-pane').removeClass('active');
        $('#step-' + step).addClass('active');

        $('.wizard-step').removeClass('active completed');
        for (var i = 1; i < step; i++) {
            $('#wizard-step-' + i).addClass('completed');
        }
        $('#wizard-step-' + step).addClass('active');

        // Show/hide buttons
        if (step > 1) {
            $('#btnPrevious').show();
        } else {
            $('#btnPrevious').hide();
        }

        if (step < totalSteps) {
            $('#btnNext').show();
            $('#<%= btn_save.ClientID %>').hide();
        } else {
            $('#btnNext').hide();
            $('#<%= btn_save.ClientID %>').show();
        }

        currentStep = step;
        $('#<%= hdnCurrentStep.ClientID %>').val(step);
    }

    function nextStep() {
        if (validateStep(currentStep)) {
            // Save summernote content before moving
            if (currentStep === 1) {
                var content = $('#summernote').summernote('code');
            <%--    $('#<%= hdnTermsContent.ClientID %>').val(content);--%>
            }
            if (currentStep < totalSteps) {
                showStep(currentStep + 1);
            }
        }
    }

    function previousStep() {
        // Save summernote content before moving
        if (currentStep === 1) {
            var content = $('#summernote').summernote('code');
          <%--  $('#<%= hdnTermsContent.ClientID %>').val(content);--%>
        }
        if (currentStep > 1) {
            showStep(currentStep - 1);
        }
    }


    function validateStep(step) {
        return true
    }
<%--    function validateStep(step) {
        var isValid = true;
        var requiredFields = [];

        if (step === 1) {
            requiredFields = [
                //{ id: '<%= txt_name.ClientID %>', name: 'Society Name' },
                //{ id: '<%= txt_es_date.ClientID %>', name: 'Establish Date' },
              //  { id: '<%= txt_registration.ClientID %>', name: 'Registration No' }
            ];
        } else if (step === 2) {
            requiredFields = [
                //{ id: '<%= txt_off_address1.ClientID %>', name: 'Office Address' },
                //{ id: '<%= txt_contact_no1.ClientID %>', name: 'Contact Number' },
              //  { id: '<%= txt_email.ClientID %>', name: 'Email' }
            ];
        } else if (step === 3) {
            requiredFields = [
                //{ id: '<%= ddl_state.ClientID %>', name: 'State', type: 'dropdown' },
                //{ id: '<%= ddl_district.ClientID %>', name: 'District', type: 'dropdown' },
                //{ id: '<%= txt_city.ClientID %>', name: 'City' },
                //{ id: '<%= txt_street.ClientID %>', name: 'Street/Home No' },
              //  { id: '<%= txt_pincode.ClientID %>', name: 'Pincode' }
            ];
        } else if (step === 4) {
            requiredFields = [
                //{ id: '<%= txt_per_sqft_rate.ClientID %>', name: 'Per Sq. Feet Rate' },
                //{ id: '<%= txt_2w_rate.ClientID %>', name: '2 Wheeler Rate' },
                //{ id: '<%= txt_4w_rate.ClientID %>', name: '4 Wheeler Rate' },
                //{ id: '<%= txt_gen_day.ClientID %>', name: 'Generation Day' },
              //  { id: '<%= txt_due_period.ClientID %>', name: 'Due Date Period' }
            ];
        }

        var missingFields = [];
        requiredFields.forEach(function (field) {
            var el = $('#' + field.id);
            var val = el.val();
            if (!val || val.trim() === '' || (field.type === 'dropdown' && (val === '0' || val === ''))) {
                el.addClass('is-invalid');
                missingFields.push(field.name);
                isValid = false;
            } else {
                el.removeClass('is-invalid');
            }
        });

        // Additional validations
        if (step === 2) {
            //var contact = $('#<%= txt_contact_no1.ClientID %>').val();
            if (contact && contact.length !== 10) {
            //    $('#<%= txt_contact_no1.ClientID %>').addClass('is-invalid');
                missingFields.push('Contact must be 10 digits');
                isValid = false;
            }
            //var email = $('#<%= txt_email.ClientID %>').val();
            var emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (email && !emailRegex.test(email)) {
          //      $('#<%= txt_email.ClientID %>').addClass('is-invalid');
                missingFields.push('Invalid email format');
                isValid = false;
            }
        }

        if (step === 3) {
            //var pincode = $('#<%= txt_pincode.ClientID %>').val();
            if (pincode && pincode.length !== 6) {
          //      $('#<%= txt_pincode.ClientID %>').addClass('is-invalid');
                missingFields.push('Pincode must be 6 digits');
                isValid = false;
            }
        }

        if (!isValid) {
            Swal.fire({
                icon: 'warning',
                title: 'Required Fields',
                html: 'Please fill: <br><strong>' + missingFields.join(', ') + '</strong>',
                confirmButtonColor: '#3085d6'
            });
        }

        return isValid;
    }--%>

    function prepareSubmit() {
        // Save summernote content to hidden field before submit
        var content = $('#summernote').summernote('code');
    <%--    $('#<%= hdnTermsContent.ClientID %>').val(content);--%>

        if (!validateStep(4)) {
            return false;
        }
        return true;
    }

    function SuccessEntry() {
        Swal.fire({
            title: '✅ Success!',
            text: 'Society Created Successfully. You Can Now Login to your Society',
            icon: 'success',
            showConfirmButton: true,
            confirmButtonColor: '#3085d6',
            confirmButtonText: 'OK',
            timer: 3000,
            timerProgressBar: true
        }).then(function () {
            window.location.href = 'login1.aspx';
        });
    }

    // Handle UpdatePanel postbacks - restore step
    var prm = Sys.WebForms.PageRequestManager.getInstance();
    prm.add_endRequest(function () {
        var savedStep = $('#<%= hdnCurrentStep.ClientID %>').val();
        if (savedStep) {
            currentStep = parseInt(savedStep);
            showStep(currentStep);
        }
        // Reinitialize summernote if needed
        if (!$('#summernote').hasClass('note-editor')) {
            initSummernote();
        }
    });

    function initSummernote() {
        $('#summernote').summernote({
            height: 200,
            toolbar: [
                ['style', ['style']],
                ['font', ['bold', 'italic', 'underline', 'clear']],
                ['fontsize', ['fontsize']],
                ['color', ['color']],
                ['para', ['ul', 'ol', 'paragraph']],
                ['view', ['fullscreen']]
            ],
            fontSizes: ['8', '10', '12', '14', '16', '18', '20', '24', '28', '32', '36']
        });
    <%--    var savedContent = $('#<%= hdnTermsContent.ClientID %>').val();--%>
        if (savedContent) {
            $('#summernote').summernote('code', savedContent);
        }
    }

    // Only allow digits for pincode
    function digit(evt) {
        var charCode = evt.which ? evt.which : evt.keyCode;
        if (charCode < 48 || charCode > 57) {
            return false;
        }
        return true;
    }
</script>
    </html>