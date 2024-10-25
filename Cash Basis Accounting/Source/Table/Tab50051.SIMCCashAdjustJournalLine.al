table 50051 "SLGI Cash Adjust. Journal Line"
{
    Caption = 'Cash Adjustment Journal Line';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Line No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Line No.';
        }
        field(3; "G/L Account No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'G/L Account No.';
            TableRelation = "G/L Account";

            trigger OnValidate();
            var
                GLA: Record "G/L Account";
            begin
                if GLA.Get("G/L Account No.") then begin
                    GLA.TestField("Account Type", GLA."Account Type"::Posting);
                    CreateDim(Database::"G/L Account", "G/L Account No.");
                    UpdateLineBalance();
                end;
            end;
        }
        field(4; "Posting Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Posting Date';
            ClosingDates = true;
        }
        field(5; "G/L Account Name"; Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("G/L Account".Name where("No." = field("G/L Account No.")));
            Editable = false;
        }
        field(11; "Document No."; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(15; Description; Text[50])
        {
            DataClassification = CustomerContent;
        }
        field(17; "Balance (LCY)"; Decimal)
        {
            DataClassification = CustomerContent;
            AutoFormatType = 1;
            Editable = false;
        }
        field(20; Amount; Decimal)
        {
            DataClassification = CustomerContent;
            trigger OnValidate();
            begin
                UpdateLineBalance();
            end;
        }
        field(23; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
            DataClassification = CustomerContent;

            trigger OnValidate();
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(24; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
            DataClassification = CustomerContent;

            trigger OnValidate();
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(51; "Journal Batch Name"; Code[10])
        {
            DataClassification = CustomerContent;
            TableRelation = "SLGI Cash Adjust. Jnl Batch";
        }
        field(52; "Reason Code"; Code[10])
        {
            DataClassification = CustomerContent;
            TableRelation = "Reason Code";
        }
        field(80; "Posting No. Series"; Code[10])
        {
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }
        field(480; "Dimension Set ID"; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup();
            begin
                ShowDimensions;
            end;
        }
    }

    keys
    {
        key(Key1; "Journal Batch Name", "Line No.")
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

    trigger OnInsert();
    var
        CashJnlBatch: Record "SLGI Cash Adjust. Jnl Batch";
    begin
        LockTable;
        CashJnlBatch.Get("Journal Batch Name");
        ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
    end;

    var
        DimMgt: Codeunit DimensionManagement;

    procedure EmptyLine(): Boolean;
    begin
        exit(
          ("G/L Account No." = '') and (Amount = 0));
    end;

    procedure UpdateLineBalance();
    begin
        "Balance (LCY)" := Amount;
    end;

    procedure CreateDim(Type1: Integer; No1: Code[20]);
    var
        SourceCodeSetup: Record "Source Code Setup";
        DimMgt: Codeunit DimensionManagement;
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        SourceCodeSetup.Get;
        DimMgt.AddDimSource(DefaultDimSource, Type1, No1);
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" :=
          DimMgt.GetDefaultDimID(
            DefaultDimSource, SourceCodeSetup."General Journal",
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code",
            "Dimension Set ID", Database::"SLGI Cash Adjust. Journal Line");
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20]);
    begin
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20]);
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        ValidateShortcutDimCode(FieldNumber, ShortcutDimCode);
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20]);
    begin
        DimMgt.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
    end;

    procedure ShowDimensions();
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", Format("Line No."));
    end;

    procedure SetUpNewLine(LastCashJnlLine: Record "SLGI Cash Adjust. Journal Line"; Balance: Decimal; BottomLine: Boolean);
    var
        CashJnlBatch: Record "SLGI Cash Adjust. Jnl Batch";
        CashJnlLine: Record "SLGI Cash Adjust. Journal Line";
        NoSeries: Codeunit "No. Series";
    begin
        if not CashJnlBatch.Get("Journal Batch Name") then
            CashJnlBatch.FindFirst();
        CashJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        if CashJnlLine.FindFirst() then begin
            "Posting Date" := LastCashJnlLine."Posting Date";
            "Document No." := LastCashJnlLine."Document No.";
            if BottomLine and
               (Balance - LastCashJnlLine."Balance (LCY)" = 0) and
               not LastCashJnlLine.EmptyLine()
            then
                "Document No." := IncStr("Document No.");
        end else begin
            "Posting Date" := WorkDate();
            if CashJnlBatch."No. Series" <> '' then begin
                Clear(NoSeries);
                "Document No." := NoSeries.PeekNextNo(CashJnlBatch."No. Series", "Posting Date");
            end;
        end;
        "Reason Code" := CashJnlBatch."Reason Code";
        Description := '';
    end;

    procedure CheckDocNoOnLines();
    var
        CashJnlBatch: Record "SLGI Cash Adjust. Jnl Batch";
        CashJnlLine: Record "SLGI Cash Adjust. Journal Line";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        LastDocNo: Code[20];
    begin
        CashJnlLine.CopyFilters(Rec);

        if not CashJnlLine.FindSet() then
            exit;
        CashJnlBatch.Get(CashJnlLine."Journal Batch Name");
        if CashJnlBatch."No. Series" = '' then
            exit;

        Clear(NoSeriesBatch);
        repeat
            CheckDocNoBasedOnNoSeries(LastDocNo, CashJnlBatch."No. Series", NoSeriesBatch);
            LastDocNo := CashJnlLine."Document No.";
        until CashJnlLine.Next() = 0;
    end;

    procedure CheckDocNoBasedOnNoSeries(LastDocNo: Code[20]; NoSeriesCode: Code[10]; var NoSeriesBatch: Codeunit "No. Series - Batch");
    begin
        if NoSeriesCode = '' then
            exit;

        if (LastDocNo = '') or ("Document No." <> LastDocNo) then
            if "Document No." <> NoSeriesBatch.GetNextNo(NoSeriesCode, "Posting Date", false) then
                NoSeriesBatch.TestManual(NoSeriesCode);  // allow use of manual document numbers.
    end;

    procedure CheckDocNoBasedOnNoSeries(LastDocNo: Code[20]; NoSeriesCode: Code[10]; var NoSeriesMgtInstance: Codeunit NoSeriesManagement);
    begin
        if NoSeriesCode = '' then
            exit;

        if (LastDocNo = '') or ("Document No." <> LastDocNo) then
            if "Document No." <> NoSeriesMgtInstance.GetNextNo(NoSeriesCode, "Posting Date", false) then
                NoSeriesMgtInstance.TestManual(NoSeriesCode);  // allow use of manual document numbers.
    end;
}

