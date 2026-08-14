
Sys.Application.add_load(function () {
    document.addEventListener("click", function (event) {
        var calendar = $find("calendarExt"); // Use the BehaviorID here
        var calendarElement = document.getElementById("CalendarExtender1");

        // Check if click is outside the calendar and textbox
        if (calendar && !event.target.closest("#txt_search") &&
            !event.target.closest("#btn_calendar") &&
            !document.querySelector(".ajax__calendar_container")?.contains(event.target)) {
            calendar.hide();
        }
    });
});


//const div1 = document.getElementById('userDropdown1');
//const div2 = document.getElementById('userDropdown2');

//// Toggle dropdown on div1 click
//div1.addEventListener('click', (e) => {
//    e.stopPropagation(); // prevent event bubbling
//    div2.style.display = div2.style.display === 'block' ? 'none' : 'block';
//});

//// Close dropdown if clicking outside
//document.addEventListener('click', (e) => {
//    if (!div1.contains(e.target) && !div2.contains(e.target)) {
//        div2.style.display = 'none';
//    }
//});

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
var lastFocusedElement = null;

// Track last focused input before postback
document.addEventListener('focusin', function (e) {
    if (e.target.tagName === "INPUT" || e.target.tagName === "TEXTAREA") {
        lastFocusedElement = e.target.name || e.target.id;
    }
});

// Refocus and move cursor to end after postback
function refocusAfterPostback() {
    if (!lastFocusedElement) return;

    var input = document.getElementsByName(lastFocusedElement)[0] || document.getElementById(lastFocusedElement);
    if (input) {
        input.focus();

        // Move cursor to end of text
        var length = input.value.length;
        input.setSelectionRange(length, length);
    }
}

function removeFocusAfterTyping() {
    clearTimeout(window.typingTimer);
    const input = document.querySelector('input[type="Search"]');
    window.typingTimer = setTimeout(function () {
        if (input) input.blur();
    }, 500);
    input.focus();
}


function showPasswordFields() {
    // Hide the "Change Password" link
    const changePasswordLink = document.getElementById('changePasswordLink');
    changePasswordLink.style.display = 'none';

    // Show the password fields container
    const passwordFieldsContainer = document.getElementById('passwordFieldsContainer');
    passwordFieldsContainer.style.display = 'block';
}

function togglePasswordVisibility() {
    const passwordField = document.getElementById('passwordField');
    const toggleIcon = document.querySelector('#togglePasswordContainer i');

    if (passwordField.type === 'password') {
        passwordField.type = 'text';
        toggleIcon.classList.remove('fa-eye');
        toggleIcon.classList.add('fa-eye-slash');
    } else {
        passwordField.type = 'password';
        toggleIcon.classList.remove('fa-eye-slash');
        toggleIcon.classList.add('fa-eye');
    }
}
function togglePasswordVisibility2() {
    const passwordField = document.getElementById('TextBox1');
    const toggleIcon = document.querySelector('#togglePasswordContainer2 i');

    if (passwordField.type === 'password') {
        passwordField.type = 'text';
        toggleIcon.classList.remove('fa-eye');
        toggleIcon.classList.add('fa-eye-slash');
    } else {
        passwordField.type = 'password';
        toggleIcon.classList.remove('fa-eye-slash');
        toggleIcon.classList.add('fa-eye');
    }
}

function toggleReEnterPasswordVisibility() {
    const reEnterPasswordField = document.getElementById('reEnterPasswordField');
    const toggleIcon = document.querySelector('#toggleReEnterPasswordContainer i');

    if (reEnterPasswordField.type === 'password') {
        reEnterPasswordField.type = 'text';
        toggleIcon.classList.remove('fa-eye');
        toggleIcon.classList.add('fa-eye-slash');
    } else {
        reEnterPasswordField.type = 'password';
        toggleIcon.classList.remove('fa-eye-slash');
        toggleIcon.classList.add('fa-eye');
    }
}

function validatePasswords() {
    const passwordField = document.getElementById('passwordField');
    const reEnterPasswordField = document.getElementById('reEnterPasswordField');
    const validationMessage = document.getElementById('passwordValidationMessage');

    if (reEnterPasswordField.value === passwordField.value) {
        validationMessage.style.display = 'none';
        reEnterPasswordField.classList.remove('is-invalid');
        reEnterPasswordField.classList.add('is-valid');
    } else {
        validationMessage.style.display = 'block';
        reEnterPasswordField.classList.remove('is-valid');
        reEnterPasswordField.classList.add('is-invalid');
    }
}



//document.addEventListener("DOMContentLoaded", function () {
//    const toggleButton = document.getElementById("sidebarTogglee");
//    const sidebar = document.querySelector(".sidebar"); // Adjust selector as needed

//    toggleButton.addEventListener("click", function (e) {
//        e.preventDefault(); // Prevent default form behavior
//        sidebar.classList.toggle("toggled");
//    });
//});

//document.addEventListener("DOMContentLoaded", function () {
//    let collapsibleMenus = document.querySelectorAll(".collapse");
//    let menuItems = document.querySelectorAll(".collapse-item");
//    let dashboardLinks = document.querySelectorAll(".nav-link[href='dashboard.aspx'], .nav-link[href='admin_dashboard.aspx'], .nav-link[href='login1.aspx']"); // Includes Logout

//    // Restore last open menu
//    let lastOpenMenu = sessionStorage.getItem("lastOpenMenu");
//    if (lastOpenMenu) {
//        let openMenu = document.getElementById(lastOpenMenu);
//        if (openMenu) {
//            openMenu.classList.add("show");
//        }
//    }

//    // Restore last clicked menu item
//    let lastClickedItem = sessionStorage.getItem("lastClickedItem");
//    if (lastClickedItem) {
//        menuItems.forEach(item => {
//            item.classList.remove("active"); // Remove active class from all
//            if (item.getAttribute("href") === lastClickedItem) {
//                item.classList.add("active"); // Set active class on last clicked item
//            }
//        });
//    }

//    // Handle menu open/close behavior
//    collapsibleMenus.forEach(menu => {
//        let id = menu.id;

//        menu.addEventListener("shown.bs.collapse", function () {
//            sessionStorage.setItem("lastOpenMenu", id);

//            // Close all other menus
//            collapsibleMenus.forEach(otherMenu => {
//                if (otherMenu.id !== id) {
//                    otherMenu.classList.remove("show");
//                    sessionStorage.removeItem(otherMenu.id);
//                }
//            });
//        });

//        menu.addEventListener("hidden.bs.collapse", function () {
//            if (sessionStorage.getItem("lastOpenMenu") === id) {
//                sessionStorage.removeItem("lastOpenMenu");
//            }
//        });
//    });

//    // Handle menu item clicks and allow navigation
//    menuItems.forEach(item => {
//        item.addEventListener("click", function (event) {
//            let clickedHref = this.getAttribute("href");

//            // Save last clicked menu item
//            sessionStorage.setItem("lastClickedItem", clickedHref);

//            let parentCollapse = this.closest(".collapse");
//            if (parentCollapse) {
//                sessionStorage.setItem("lastOpenMenu", parentCollapse.id);
//            }

//            // Highlight the active menu item
//            menuItems.forEach(i => i.classList.remove("active"));
//            this.classList.add("active");

//            // **Allow page navigation**
//            if (clickedHref !== "#" && clickedHref !== "") {
//                window.location.href = clickedHref;
//            }
//        });
//    });

//    // **Handle Admin Dashboard & Logout Click: Collapse Master Tab**
//    if (dashboardLinks.length > 0) {
//        dashboardLinks.forEach(link => {
//            link.addEventListener("click", function () {
//                sessionStorage.removeItem("lastOpenMenu"); // Clear stored menu
//            });
//        });
//    }
//});



$('.modal').on('hidden.bs.modal', function () {
    const modal = $(this);

    modal.find('input, select, textarea').each(function () {
        // ✅ Always re-enable disabled fields
        if (this.disabled) {
            this.disabled = false;
        }
         
        const type = (this.type || '').toLowerCase();

        switch (type) {
            case 'text':
            case 'email':
            case 'password':
            case 'number':
            case 'date':
            case 'search':
            case 'tel':
            case 'url':
            case 'file':
            case 'textarea':
            case 'hidden':
                $(this).val('');
                break;

            case 'checkbox':
            case 'radio':
                this.checked = false;
                break;

            case 'select-one':
            case 'select-multiple':
                this.selectedIndex = 0;
                break;
        }
    });


    // ✅ Optional: clear validation messages, error classes, or alerts if you use them
    modal.find('.is-invalid, .is-valid').removeClass('is-invalid is-valid');
    modal.find('.text-danger, .validation-message, .alert').remove();

});




function resetForm() {


    const form = document.getElementById("myForm");

    // Reset the entire form (works for most input types)
    form.reset();

    // Additionally, manually clear all input fields to ensure complete reset
    form.querySelectorAll("input, textarea, select").forEach(input => {
        switch (input.type) {
            case 'text':
            case 'email':
            case 'password':
            case 'number':
            case 'date':
            case 'search':
            case 'tel':
            case 'url':
            case 'textarea':
                input.value = '';
                break;
            case 'checkbox':

            case 'radio':
                input.checked = false;
                break;
            case 'select-one':
            case 'select-multiple':
                input.selectedIndex = 0;
                break;
        }
    });
}

(function () {
    'use strict';

    const forms = document.querySelectorAll('.needs-validation');

    Array.prototype.slice.call(forms).forEach(function (form) {
        let submittedOnce = false;
         
        function validateField(input) {
            const tag = input.tagName.toLowerCase();
            const type = input.type.toLowerCase();

            const value = input.value.trim();
            const validTypes = ['text', 'email', 'password', 'search', 'tel', 'url', 'contact', 'vehicle'];

            // Common whitespace check
            if ((validTypes.includes(type) || tag === 'textarea') && input.required) {
                if (value === '') {
                    input.setCustomValidity('Whitespace is not allowed');
                    showInvalid(input);
                    return;
                } else {
                    input.setCustomValidity('');
                }
            }

            // Additional type-based validations
            if (type === 'email' && value !== '') {
                const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                if (!emailRegex.test(value)) {
                    input.setCustomValidity('Please enter a valid email address');
                    showInvalid(input);
                    return;
                } else {
                    input.setCustomValidity('');
                }
            }

            if (type === 'url' && value !== '') {
                try {
                    new URL(value); // throws if invalid
                    input.setCustomValidity('');
                } catch {
                    input.setCustomValidity('Please enter a valid URL');
                    showInvalid(input);
                    return;
                }
            }

            if ((type === 'tel' || type === 'Phone' || type === 'contact') && value !== '') {
                const phoneRegex = /^\d{10}$/; // Only digits, exactly 10
                if (!phoneRegex.test(value)) {
                    input.setCustomValidity('Phone number must be exactly 10 digits');
                    showInvalid(input);
                    return;
                } else {
                    input.setCustomValidity('');
                }
            }

            if ((type === 'text' && input.dataset.type === 'vehicle') && value !== '') {
                const phoneRegex = /^[A-Z]{2}\s?-?\d{1, 2}\s?-?[A-Z]{1, 2}\s?-?\d{4}$/;
                if (!phoneRegex.test(value)) {
                    input.setCustomValidity('Incorrect Vehicle number');
                    showInvalid(input);
                    return;
                } else {
                    input.setCustomValidity('');
                }
            }
            // Dropdown (select) validation
            //if (tag === 'select' && input.required) {
            //    if (input.value === '0') {
            //        input.setCustomValidity('Please select a valid option');
            //        showInvalid(input);
            //        return;
            //    } else {
            //        input.setCustomValidity('');
            //    }
            //}

            // Final validation state
            if (!input.checkValidity()) {
                showInvalid(input);
            } else {
                showValid(input);
            }
        }


        function showInvalid(input) {
            input.classList.remove('is-valid');
            input.classList.add('is-invalid');
        }

        function showValid(input) {
            input.classList.remove('is-invalid');
            input.classList.add('is-valid');
        }

        form.addEventListener('submit', function (event) {
            submittedOnce = true;
            let hasCustomError = false;

            form.querySelectorAll('input, textarea').forEach(function (input) {
                validateField(input);
                if (!input.checkValidity()) {
                    hasCustomError = true;
                }
            });

            if (hasCustomError) {
                event.preventDefault();
                event.stopPropagation();
            }

            form.classList.add('was-validated');
        }, false);

        // Live validation 
        form.querySelectorAll('input, textarea').forEach(function (input) {
            input.addEventListener('input', function () {
                if (submittedOnce) {
                    validateField(input);
                }
            });
        });
    });
})();





//          const addNoteBtn = document.getElementById("addNoteBtn");
//const showNotesBtn = document.getElementById("showNotesBtn");
//const notePopup = document.getElementById("notePopup");
//const saveNoteBtn = document.getElementById("saveNoteBtn");
//const cancelBtn = document.getElementById("cancelBtn");
//const noteHeader = document.getElementById("noteHeader");
//const noteContent = document.getElementById("noteContent");
//const notesContainer = document.getElementById("notesContainer");
//const popupTitle = document.getElementById("popupTitle");

//let notes = JSON.parse(localStorage.getItem("notes")) || [];
//let editIndex = null;

//function renderNotes() {
//    notesContainer.innerHTML = "";

//    if (notes.length > 0) {
//        notesContainer.style.display = "flex";
//        addNoteBtn.style.display = "none";
//        showNotesBtn.style.display = "inline-block";
//    } else {
//        notesContainer.style.display = "none";
//        addNoteBtn.style.display = "inline-block";
//        showNotesBtn.style.display = "none";
//    }

//    notes.forEach((note, index) => {
//        const noteEl = document.createElement("div");
//        noteEl.className = "note-note";
//        noteEl.innerHTML = `
//          <h4>${note.title}</h4>
//          <p>${note.content}</p>
//          <button class="note-edit">Edit</button>
//          <button class="note-delete">X</button>
//        `;

//        noteEl.querySelector(".note-edit").addEventListener("click", () => editNote(index));
//        noteEl.querySelector(".note-delete").addEventListener("click", () => deleteNote(index));

//        notesContainer.appendChild(noteEl);
//    });
//}

//function saveNote() {
//    const title = noteHeader.value.trim();
//    const content = noteContent.value.trim();

//    if (title && content) {
//        const noteData = { title, content };

//        if (editIndex !== null) {
//            notes[editIndex] = noteData;
//            editIndex = null;
//        } else {
//            notes.push(noteData);
//        }

//        localStorage.setItem("notes", JSON.stringify(notes));
//        renderNotes();
//        closePopup();
//    } else {
//        alert("Please fill both fields.");
//    }
//}

//function deleteNote(index) {
//    if (confirm("Delete this note?")) {
//        notes.splice(index, 1);
//        localStorage.setItem("notes", JSON.stringify(notes));
//        renderNotes();
//    }
//}

//function editNote(index) {
//    const note = notes[index];
//    noteHeader.value = note.title;
//    noteContent.value = note.content;
//    popupTitle.textContent = "Edit Note";
//    editIndex = index;
//    notePopup.style.display = "flex";
//}

//function openPopup() {
//    noteHeader.value = "";
//    noteContent.value = "";
//    popupTitle.textContent = "Add Note";
//    editIndex = null;
//    notePopup.style.display = "flex";
//}

//function closePopup() {
//    notePopup.style.display = "none";
//}

//function toggleNotes() {
//    const isVisible = notesContainer.style.display === "flex";
//    notesContainer.style.display = isVisible ? "none" : "flex";
//    addNoteBtn.style.display = isVisible ? "inline-block" : "none";
//}

//addNoteBtn.addEventListener("click", openPopup);
//cancelBtn.addEventListener("click", closePopup);
//saveNoteBtn.addEventListener("click", saveNote);
//showNotesBtn.addEventListener("click", toggleNotes);

//window.onload = renderNotes;

(function () {
    function initDraggableModal(modalSelector) {
        const modal = document.querySelector(modalSelector);
        if (!modal) return;
        const dialog = modal.querySelector('.modal-dialog');
        const header = modal.querySelector('.modal-header');
        if (!dialog || !header) return;
        if (dialog.dataset.draggableInit === '1') return; // don't double-init
        dialog.dataset.draggableInit = '1';

        let isDragging = false;
        let startX = 0, startY = 0, currentLeft = 0, currentTop = 0;
        let originalStyles = {}; // Store all original computed styles

        // ignore clicks on header buttons/links (close/save)
        const ignoreSelector = 'button, a, .btn, .close, [data-dismiss]';

        function getClientXY(e) {
            if (e.touches && e.touches.length) return { x: e.touches[0].clientX, y: e.touches[0].clientY };
            return { x: e.clientX, y: e.clientY };
        }

        function onDown(e) {
            // left mouse button only
            if (e.type === 'mousedown' && e.button !== 0) return;
            if (e.target && e.target.closest && e.target.closest(ignoreSelector)) return;

            // Get current position and dimensions BEFORE any changes
            const rect = dialog.getBoundingClientRect();
            const computedStyle = window.getComputedStyle(dialog);

            // Store original styles if not already stored
            if (!originalStyles.width) {
                originalStyles = {
                    width: rect.width,
                    height: rect.height,
                    minWidth: computedStyle.minWidth,
                    maxWidth: computedStyle.maxWidth,
                    minHeight: computedStyle.minHeight,
                    maxHeight: computedStyle.maxHeight
                };
            }

            const pt = getClientXY(e);
            startX = pt.x;
            startY = pt.y;

            // Use current position from bounding rect
            currentLeft = rect.left;
            currentTop = rect.top;

            // Apply fixed positioning with exact dimensions FIRST
            dialog.style.width = originalStyles.width + 'px';
            dialog.style.minWidth = originalStyles.width + 'px';
            dialog.style.maxWidth = originalStyles.width + 'px';
            dialog.style.height = 'auto';
            dialog.style.minHeight = '0';
            dialog.style.maxHeight = 'none';

            // Then set position
            dialog.style.position = 'fixed';
            dialog.style.left = currentLeft + 'px';
            dialog.style.top = currentTop + 'px';
            dialog.style.right = 'auto';
            dialog.style.bottom = 'auto';
            dialog.style.margin = '0';

            // Remove any transforms
            dialog.style.transform = 'none';
            dialog.style.transition = 'none';
            dialog.style.willChange = 'left, top';

            // Prevent any flex/grid parent interference
            dialog.style.flexShrink = '0';
            dialog.style.flexGrow = '0';

            // disable text selection while dragging
            document.body.style.userSelect = 'none';

            isDragging = true;

            // Add cursor style to show dragging
            header.style.cursor = 'grabbing';
            document.body.style.cursor = 'grabbing';

            // prevent page scrolling while dragging (touch)
            if (e.type.startsWith('touch')) e.preventDefault();
        }

        function onMove(e) {
            if (!isDragging) return;
            const pt = getClientXY(e);
            if (!pt) return;

            // Calculate movement delta
            const dx = pt.x - startX;
            const dy = pt.y - startY;

            // Update position
            let newLeft = currentLeft + dx;
            let newTop = currentTop + dy;

            // Get viewport dimensions
            const vw = Math.max(document.documentElement.clientWidth || 0, window.innerWidth || 0);
            const vh = Math.max(document.documentElement.clientHeight || 0, window.innerHeight || 0);
            const minVisible = 50;

            const modalWidth = originalStyles.width;
            const modalHeight = dialog.offsetHeight;

            // Constrain to viewport (keep some portion visible)
            const minLeft = -(modalWidth - minVisible);
            const maxLeft = vw - minVisible;
            const minTop = 0;
            const maxTop = vh - minVisible;

            newLeft = Math.min(Math.max(newLeft, minLeft), maxLeft);
            newTop = Math.min(Math.max(newTop, minTop), maxTop);

            // Apply new position
            dialog.style.left = newLeft + 'px';
            dialog.style.top = newTop + 'px';

            // prevent selection/scroll while dragging
            e.preventDefault();
        }

        function onUp() {
            if (!isDragging) return;
            isDragging = false;
            dialog.style.willChange = '';
            document.body.style.userSelect = '';
            header.style.cursor = 'grab';
            document.body.style.cursor = '';
        }

        // Add grab cursor to header
        header.style.cursor = 'grab';

        header.addEventListener('mousedown', onDown);
        header.addEventListener('touchstart', onDown, { passive: false });

        document.addEventListener('mousemove', onMove);
        document.addEventListener('touchmove', onMove, { passive: false });

        document.addEventListener('mouseup', onUp);
        document.addEventListener('touchend', onUp);
        document.addEventListener('touchcancel', onUp);
        window.addEventListener('blur', onUp);

        // Reset dialog inline styles when modal closes
        function resetStyles() {
            dialog.style.left = '';
            dialog.style.top = '';
            dialog.style.right = '';
            dialog.style.bottom = '';
            dialog.style.position = '';
            dialog.style.transform = '';
            dialog.style.margin = '';
            dialog.style.transition = '';
            dialog.style.willChange = '';
            dialog.style.zIndex = '';
            dialog.style.width = '';
            dialog.style.minWidth = '';
            dialog.style.maxWidth = '';
            dialog.style.height = '';
            dialog.style.minHeight = '';
            dialog.style.maxHeight = '';
            dialog.style.flexShrink = '';
            dialog.style.flexGrow = '';
            document.body.style.userSelect = '';
            document.body.style.cursor = '';
            header.style.cursor = 'grab';
            originalStyles = {}; // Clear stored styles
        }

        if (window.jQuery) {
            jQuery(modal).on('hidden.bs.modal', resetStyles);
            // Also reset when modal is shown (to ensure fresh state)
            jQuery(modal).on('shown.bs.modal', function () {
                originalStyles = {};
            });
        } else {
            modal.addEventListener('hidden.bs.modal', resetStyles);
            modal.addEventListener('shown.bs.modal', function () {
                originalStyles = {};
            });
        }
    }

    // init on DOM ready
    function initAllModals() {
        document.querySelectorAll('.modal').forEach(m => {
            if (m.id) {
                initDraggableModal('#' + m.id);
            }
        });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initAllModals);
    } else {
        initAllModals();
    }

    // If using ASP.NET UpdatePanel re-init after partial postback
    if (window.Sys && Sys.WebForms && Sys.WebForms.PageRequestManager) {
        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(initAllModals);
    }
})();



//document.addEventListener("DOMContentLoaded", function () {
//    const panels = document.querySelectorAll(".collapse");
//    const currentPath = window.location.pathname.toLowerCase();
//    const cleanPath = currentPath.split(/[?#]/)[0];
//    let matchedPanelId = null;

//     Clear previous highlights
//    document.querySelectorAll(".active-link").forEach(el => el.classList.remove("active-link"));
//    document.querySelectorAll(".active-panel").forEach(el => el.classList.remove("active-panel"));

//    panels.forEach(panel => {
//        const links = panel.querySelectorAll("a[href]");
//        links.forEach(link => {
//            const href = link.getAttribute("href").toLowerCase();
//            if (cleanPath.endsWith(href)) {
//                link.classList.add("active-link");
//                panel.classList.add("show");

//                const toggle = document.querySelector(`[data-target="#${panel.id}"]`);
//                if (toggle) {
//                    toggle.setAttribute("aria-expanded", "true");
//                    toggle.classList.remove("collapsed");

//                    const parentLi = toggle.closest("li");
//                    if (parentLi) {
//                        parentLi.classList.add("active-panel");
//                    }
//                }

//                matchedPanelId = panel.id;
//            }
//        });
//    });

//     //Restore from localStorage if no match found
//    if (!matchedPanelId) {
//        const openPanelId = localStorage.getItem("openSidebarPanel");
//        if (openPanelId) {
//            const fallbackPanel = document.getElementById(openPanelId);
//            if (fallbackPanel) {
//                fallbackPanel.classList.add("show");
//                const toggle = document.querySelector(`[data-target="#${fallbackPanel.id}"]`);
//                if (toggle) {
//                    toggle.setAttribute("aria-expanded", "true");
//                    toggle.classList.remove("collapsed");

//                    const parentLi = toggle.closest("li");
//                    if (parentLi) {
//                        parentLi.classList.add("active-panel");
//                    }

//                    const fallbackLinks = fallbackPanel.querySelectorAll("a[href]");
//                    fallbackLinks.forEach(link => {
//                        const href = link.getAttribute("href").toLowerCase();
//                        if (cleanPath.endsWith(href)) {
//                            link.classList.add("active-link");
//                        }
//                    });
//                }
//            }
//        }
//    }

//     //Save the last opened panel to localStorage
//    panels.forEach(panel => {
//        const toggle = document.querySelector(`[data-target="#${panel.id}"]`);
//        if (toggle) {
//            toggle.addEventListener("click", function () {
//                localStorage.setItem("openSidebarPanel", panel.id);
//            });
//        }
//    });
//});
