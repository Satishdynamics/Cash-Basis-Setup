table 50050 "SLGI Cash G/L Entry"
{
    Caption = 'Cash Ledger Entry';
    DataClassification = CustomerContent;
    DrillDownPageId = "SLGI Cash G/L Entries";
    LookupPageId = "SLGI Cash G/L Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = CustomerContent;
        }
        field(3; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            TableRelation = "G/L Account";
            DataClassification = CustomerContent;
        }
        field(4; "Posting Date"; Date)
        {
            ClosingDates = true;
            DataClassification = CustomerContent;
        }
        field(5; "G/L Account Name"; Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("G/L Account".Name where("No." = field("G/L Account No.")));
            Editable = false;
        }
        field(10; "Document Type"; Enum "SLGI CSH Document Type")
        {
            DataClassification = CustomerContent;
        }
        field(11; "Document No."; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(12; "Document Posting Date"; Date)
        {
            DataClassification = CustomerContent;
        }
        field(13; "GL Document Type"; Enum "Gen. Journal Document Type")
        {
            DataClassification = CustomerContent;
            // OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund;
        }
        field(14; "Source Type"; Option)
        {
            DataClassification = CustomerContent;
            OptionMembers = " ",Customer,Vendor,"Bank Account","Fixed Asset",Employee;
        }
        field(15; "Source No."; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Vendor)) Vendor
            else
            if ("Source Type" = const("Bank Account")) "Bank Account"
            else
            if ("Source Type" = const("Fixed Asset")) "Fixed Asset"
            else
            if ("Source Type" = const(Employee)) Employee;
        }
        // Extended fro 50 to 100 chars
        field(16; "Source Name"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(20; Amount; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(23; "Global Dimension 1 Code"; Code[20])
        {
            DataClassification = CustomerContent;
            CaptionClass = '1,1,1';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(24; "Global Dimension 2 Code"; Code[20])
        {
            DataClassification = CustomerContent;
            CaptionClass = '1,1,2';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(53; "Debit Amount"; Decimal)
        {
            DataClassification = CustomerContent;
            AutoFormatType = 1;
            BlankZero = true;
        }
        field(54; "Credit Amount"; Decimal)
        {
            DataClassification = CustomerContent;
            AutoFormatType = 1;
            BlankZero = true;
        }
        field(60; "Applied Document Type"; Option)
        {
            DataClassification = CustomerContent;
            OptionMembers = " ","Sales Invoice","Sales Cr. Memo","Purchase Invoice","Purchase Cr. Memo","G/L Entry",Adjustment,Payment,Refund;
        }
        field(61; "Applied Document No."; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(62; "Applied Date"; Date)
        {
            DataClassification = CustomerContent;
        }
        field(70; "Payment No."; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(71; "Created On"; Date)
        {
            DataClassification = CustomerContent;
        }
        field(75; "From Balance G/L"; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup();
            begin
                ShowDimensions();
            end;
        }
        field(481; "Shortcut Dimension 3 Code"; Code[20])
        {
            CaptionClass = '1,2,3';
            Caption = 'Shortcut Dimension 3 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(3)));
        }
        field(482; "Shortcut Dimension 4 Code"; Code[20])
        {
            CaptionClass = '1,2,4';
            Caption = 'Shortcut Dimension 4 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(4)));
        }
        field(483; "Shortcut Dimension 5 Code"; Code[20])
        {
            CaptionClass = '1,2,5';
            Caption = 'Shortcut Dimension 5 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(5)));
        }
        field(484; "Shortcut Dimension 6 Code"; Code[20])
        {
            CaptionClass = '1,2,6';
            Caption = 'Shortcut Dimension 6 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(6)));
        }
        field(485; "Shortcut Dimension 7 Code"; Code[20])
        {
            CaptionClass = '1,2,7';
            Caption = 'Shortcut Dimension 7 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(7)));
        }
        field(486; "Shortcut Dimension 8 Code"; Code[20])
        {
            CaptionClass = '1,2,8';
            Caption = 'Shortcut Dimension 8 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(8)));
        }

    }

    keys
    {
        key(Key1; "Entry No.")
        {
        }
        key(Key2; "G/L Account No.", "Global Dimension 1 Code", "Global Dimension 2 Code", "Posting Date")
        {
            SumIndexFields = Amount, "Debit Amount", "Credit Amount";
        }
        key(Key3; "G/L Account No.", "Posting Date")
        {
            SumIndexFields = Amount, "Debit Amount", "Credit Amount";
        }
        key(Key4; "Posting Date")
        {
        }
    }

    fieldgroups
    {
    }

    var
        GLSetup: Record "General Ledger Setup";

    procedure GetCurrencyCode(): Code[10]
    begin
        GLSetup.Get();
        exit(GLSetup."Additional Reporting Currency");
    end;

    procedure GetLastEntryNo(): Integer
    begin
        if not Rec.FindLast() then
            exit(0)
        else
            exit(Rec."Entry No.");

    end;

    procedure ShowDimensions();
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", CopyStr(StrSubstNo('%1 %2', TableCaption(), "Entry No."), 1, 250));
    end;
}

