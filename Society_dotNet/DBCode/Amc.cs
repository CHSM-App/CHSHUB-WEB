using System;

namespace DBCode.DataClass
{
    public class AmcBalanceSheet
    {
        private string _societyId;
        private string _sqlOperation;
        private int _status;

        private int _auditHeaderId;
        private int _mainPointId;
        private string _mainPoint;
        private int _auditQuestionId;
        private string _auditQuestion;
        private string _auditAnswer;

        private int _balanceHeaderId;
        private string _headerDescription;
        private string _entryType;
        private decimal _headerAmount;
        private int _balanceSubpointId;
        private string _subpointDescription;
        private decimal _amount;

        private int _amcId;
        private int _sequence;
        private int _sequenceOrder;

        private DateTime _createdDate;
        private DateTime _modifiedDate;
        private string _createdBy;
        private string _modifiedBy;
        private string _remarks;


        public string SocietyID
        {
            get { return _societyId; }
            set { _societyId = value; }
        }

        public string Operation
        {
            get { return _sqlOperation; }
            set { _sqlOperation = value; }
        }

        public int Status
        {
            get { return _status; }
            set { _status = value; }
        }

        public int AuditHeaderID
        {
            get { return _auditHeaderId; }
            set { _auditHeaderId = value; }
        }

        public int MainPointID
        {
            get { return _mainPointId; }
            set { _mainPointId = value; }
        }

        public string MainPointText
        {
            get { return _mainPoint; }
            set { _mainPoint = value; }
        }

        public int AuditQuestionID
        {
            get { return _auditQuestionId; }
            set { _auditQuestionId = value; }
        }

        public string AuditQuestionText
        {
            get { return _auditQuestion; }
            set { _auditQuestion = value; }
        }

        public string AuditAnswerText
        {
            get { return _auditAnswer; }
            set { _auditAnswer = value; }
        }

        public int BalanceHeaderID
        {
            get { return _balanceHeaderId; }
            set { _balanceHeaderId = value; }
        }

        public string HeaderText
        {
            get { return _headerDescription; }
            set { _headerDescription = value; }
        }

        public string EntryCategory
        {
            get { return _entryType; }
            set { _entryType = value; }
        }

        public decimal HeaderAmount
        {
            get { return _headerAmount; }
            set { _headerAmount = value; }
        }

        public int BalanceSubpointID
        {
            get { return _balanceSubpointId; }
            set { _balanceSubpointId = value; }
        }

        public string SubpointText
        {
            get { return _subpointDescription; }
            set { _subpointDescription = value; }
        }

        public decimal Amount
        {
            get { return _amount; }
            set { _amount = value; }
        }

        public int AmcID
        {
            get { return _amcId; }
            set { _amcId = value; }
        }

        public int Sequence
        {
            get { return _sequence; }
            set { _sequence = value; }
        }

        public int SequenceOrder
        {
            get { return _sequenceOrder; }
            set { _sequenceOrder = value; }
        }

        public DateTime CreatedDate
        {
            get { return _createdDate; }
            set { _createdDate = value; }
        }

        public DateTime ModifiedDate
        {
            get { return _modifiedDate; }
            set { _modifiedDate = value; }
        }

        public string CreatedBy
        {
            get { return _createdBy; }
            set { _createdBy = value; }
        }

        public string ModifiedBy
        {
            get { return _modifiedBy; }
            set { _modifiedBy = value; }
        }

        public string Remarks
        {
            get { return _remarks; }
            set { _remarks = value; }
        }

        
    }
}
