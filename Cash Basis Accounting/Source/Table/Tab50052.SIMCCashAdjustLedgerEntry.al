table 50052 "SLGI Cash Adjust. Ledger Entry"
{
    Caption = 'Cash Adjustment Ledger Entry';
    DataClassification = CustomerContent;
    DrillDownPageId = "SLGI Cash Adjustment Ledger";
    LookupPageId = "SLGI Cash Adjustment Ledger";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Entry No.';
        }
        field(3; "G/L Account No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'G/L Account No.';
            TableRelation = "G/L Account";
        }
        field(4; "Posting Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Posting Date';
            ClosingDates = true;
        }
        field(11; "Document No."; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(15; Description; Text[50])
        {
            DataClassification = CustomerContent;
        }
        field(20; Amount; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(23; "Shortcut Dimension 1 Code"; Code[20])
        {
            DataClassification = CustomerContent;
            CaptionClass = '1,1,1';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(24; "Shortcut Dimension 2 Code"; Code[20])
        {
            DataClassification = CustomerContent;
            CaptionClass = '1,1,2';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(27; "User ID"; Code[50])
        {
            DataClassification = CustomerContent;
        }
        field(59; "No. Series"; Code[10])
        {
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }
        field(480; "Dimension Set ID"; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
        }
        key(Key2; "G/L Account No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Posting Date")
        {
            SumIndexFields = Amount;
        }
        key(Key3; "Posting Date")
        {
        }
    }

    fieldgroups
    {
    }

    var
        DimMgt: Codeunit DimensionManagement;

    procedure ShowDimensions();
    var
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", CopyStr(StrSubstNo('%1 %2', TableCaption(), "Entry No."), 1, 250));
    end;
}

