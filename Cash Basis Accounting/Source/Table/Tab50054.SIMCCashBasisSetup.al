table 50054 "SLGI Cash Basis Setup"
{
    Caption = 'Cash Basis Setup';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = CustomerContent;
        }
        field(2; "Ignore Before Date"; Date)
        {
            DataClassification = CustomerContent;
            trigger OnValidate();
            begin
                if "Ignore Before Date" = 0D then
                    "Do Not Delete Before Date" := false;
                CheckCashAccYear("Ignore Before Date");
            end;
        }
        field(3; "Do Not Delete Before Date"; Boolean)
        {
            DataClassification = CustomerContent;
            trigger OnValidate();
            begin
                TestField("Ignore Before Date");
            end;
        }
        field(4; "Allow Exclude Cash Editable"; Boolean)
        {
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                if "Allow Exclude Cash Editable" then
                    Message('WARNING. Please be aware that turning this on, means that you can make one-legged entries in the cash ledger.')
            end;
        }
        field(5; "Allow Doc. Posting in G/L Jnl."; Boolean)
        {
            DataClassification = CustomerContent;
            ObsoleteState = Pending;
            ObsoleteReason = 'Will no longer be used';
        }

        field(10; "Retained Earnings"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
        field(11; "Overpayment Account"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
        field(101; "Expiration Date"; Date)
        {
            DataClassification = CustomerContent;
            Editable = false;
            ObsoleteState = Removed;
        }
        field(102; "Trial Period"; Boolean)
        {
            DataClassification = CustomerContent;
            Editable = false;
            ObsoleteState = Removed;
        }
        field(103; "Licensed Company Name"; Text[100])
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            ObsoleteState = Removed;
        }
        field(104; "Do not show Sub Notifications"; Boolean)
        {
            Caption = 'Don''t show subscription notifications';
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
        }
        field(105; "Activation Code"; Text[250])
        {
            DataClassification = EndUserPseudonymousIdentifiers;
            Editable = false;
            ObsoleteState = Removed;
        }
        field(300; "Exp Date"; Date)
        {
            Caption = 'Expiration Date';
            //FieldClass = FlowField;
            Editable = false;
            ///CalcFormula = lookup("SLGI SUB Licensed App"."Expiration Date" where("App Code" = const('CSH')));
        }
        field(301; "Trl Period"; Boolean)
        {
            Caption = 'Trial Period';
            //FieldClass = FlowField;
            Editable = false;
            // CalcFormula = lookup("SLGI SUB Licensed App"."Trial Period" where("App Code" = const('CSH')));
        }
        field(302; "Lic Company Name"; Text[250])
        {
            Caption = 'Licensed Company Name';
            //FieldClass = FlowField;
            Editable = false;
            //CalcFormula = lookup("SLGI SUB Licensed App"."Licensed Company Name" where("App Code" = const('CSH')));
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
        }
    }

    fieldgroups
    {
    }
    procedure CreateStandardSetup();
    begin
        if not Get() then begin
            "Primary Key" := '';
            Insert();
        end;
    end;

    local procedure CheckCashAccYear(StartDate: Date)
    var
        AccountPeriod: Record "Accounting Period";
        StartDateErrorTxt: Label 'Ignore Before Date %1 must be the starting date of a cash accounting year.';
    begin
        if (StartDate = 0D) then
            exit;
        if not AccountPeriod.Get(StartDate) or not AccountPeriod."SLGI CSH New Cash Fiscal Year" then
            Error(StartDateErrorTxt, StartDate);
    end;

}

