report 50058 "SLGI CSH Exp Ledger to Excel"
{
    Caption = 'Cash Basis Export Ledger to Excel';
    UsageCategory = ReportsAndAnalysis;
    ProcessingOnly = true;
    ApplicationArea = All;

    dataset
    {
        dataitem("SLGI Cash G/L Entry"; "SLGI Cash G/L Entry")
        {
            RequestFilterFields = "Posting Date";
            trigger OnAfterGetRecord()
            var
                I: Integer;
            begin
                DimMgmt.GetDimensionSet(DimSetEntry, "SLGI Cash G/L Entry"."Dimension Set ID");
                Clear(Dims);
                TempDimSet.Reset;
                if DimSetEntry.FindSet then
                    repeat
                        TempDimSet.SetRange("Dimension Code", DimSetEntry."Dimension Code");
                        TempDimSet.FindSet;
                        Dims[TempDimSet."Dimension Set ID"] := DimSetEntry."Dimension Value Code";
                    until DimSetEntry.Next = 0;

                MakeExcelDataBody();
            end;

            trigger OnPreDataItem()
            begin
                MakeExcelDataHeader();
            end;
        }
    }

    trigger OnPostReport()
    begin
        CreateExcelBook();
    end;

    local procedure MakeExcelDataHeader()
    begin
        ExcelBuf.NewRow();
        ExcelBuf.AddColumn("SLGI Cash G/L Entry".FieldCaption("Entry No."), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry".FieldCaption("G/L Account No."), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry".FieldCaption("G/L Account Name"), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry".FieldCaption("Posting Date"), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry".FieldCaption("Document Type"), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry".FieldCaption("Document No."), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry".FieldCaption("Document Posting Date"), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry".FieldCaption(Amount), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry".FieldCaption("Debit Amount"), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry".FieldCaption("Credit Amount"), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry".FieldCaption("Applied Document Type"), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry".FieldCaption("Applied Document No."), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry".FieldCaption("Applied Date"), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry".FieldCaption("Source Type"), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry".FieldCaption("Source No."), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry".FieldCaption("Source Name"), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry".FieldCaption("GL Document Type"), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry".FieldCaption("Payment No."), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry".FieldCaption("From Balance G/L"), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry".FieldCaption("Dimension Set ID"), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(GetDimLabel(1), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(GetDimLabel(2), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(GetDimLabel(3), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(GetDimLabel(4), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(GetDimLabel(5), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(GetDimLabel(6), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(GetDimLabel(7), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(GetDimLabel(8), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(GetDimLabel(9), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(GetDimLabel(10), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(GetDimLabel(11), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(GetDimLabel(12), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
    end;

    local procedure MakeExcelDataBody()
    var
        CurrencyCodeToPrint: Code[20];
    begin
        "SLGI Cash G/L Entry".CalcFields("G/L Account Name");
        ExcelBuf.NewRow();
        ExcelBuf.AddColumn("SLGI Cash G/L Entry"."Entry No.", false, '', false, false, false, '', ExcelBuf."Cell Type"::Number);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry"."G/L Account No.", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry"."G/L Account Name", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry"."Posting Date", false, '', false, false, false, '', ExcelBuf."Cell Type"::Date);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry"."Document Type", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry"."Document No.", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry"."Document Posting Date", false, '', false, false, false, '', ExcelBuf."Cell Type"::Date);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry".Amount, false, '', false, false, false, '', ExcelBuf."Cell Type"::Number);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry"."Debit Amount", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry"."Credit Amount", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry"."Applied Document Type", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry"."Applied Document No.", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry"."Applied Date", false, '', false, false, false, '', ExcelBuf."Cell Type"::Date);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry"."Source Type", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry"."Source No.", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry"."Source Name", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry"."GL Document Type", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry"."Payment No.", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry"."From Balance G/L", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("SLGI Cash G/L Entry"."Dimension Set ID", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Dims[1], false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Dims[2], false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Dims[3], false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Dims[4], false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Dims[5], false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Dims[6], false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Dims[7], false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Dims[8], false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Dims[9], false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Dims[10], false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Dims[11], false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Dims[12], false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);

    end;

    local procedure CreateExcelBook()
    begin
        ExcelBuf.CreateNewBook('Cash Basis Ledger Entries');
        ExcelBuf.WriteSheet('Cash Basis Ledger', CompanyName(), UserId());
        ExcelBuf.CloseBook();
        ExcelBuf.OpenExcel();
    end;

    trigger OnPreReport()
    begin
        LoadDimensions();
        ExcelBuf.DeleteAll();
    end;


    local procedure LoadDimensions()
    var
        I: Integer;
        Dimension: Record Dimension;
    begin
        I := 1;
        if Dimension.FindSet then
            repeat
                TempDimSet."Dimension Set ID" := I;
                TempDimSet."Dimension Code" := Dimension.Code;
                TempDimSet.Insert;
                I += 1;
            until Dimension.Next = 0;
    end;

    local procedure GetDimLabel(I: Integer): Code[20]
    begin
        TempDimSet.SetRange("Dimension Set ID", I);
        if TempDimSet.FindSet then
            exit(TempDimSet."Dimension Code")
        else
            exit('');
    end;

    var
        ExcelBuf: Record "Excel Buffer" temporary;
        DimMgmt: Codeunit DimensionManagement;
        DimSetEntry: Record "Dimension Set Entry" temporary;
        Dims: array[12] of Code[20];
        TempDimSet: Record "Dimension Set Entry" temporary;

}