xmlport 50051 "SLGI CSH Export Cash Ledger 2"
{
    // version SlgCash 2019.11

    Direction = Export;
    Format = VariableText;

    schema
    {
        textelement(Root)
        {
            tableelement(Integer; Integer)
            {
                XmlName = 'Integer';
                SourceTableView = sorting(Number)
                                  where(Number = const(1));
                textelement(AccountNoLbl)
                {

                    trigger OnBeforePassVariable()
                    begin
                        AccountNoLbl := "SLGI Cash G/L Entry".FieldCaption("G/L Account No.");
                    end;
                }
                textelement(AccountNameLbl)
                {

                    trigger OnBeforePassVariable()
                    begin
                        AccountNameLbl := GLAccount.FieldCaption(Name);
                    end;
                }
                textelement(PostDateLbl)
                {

                    trigger OnBeforePassVariable()
                    begin
                        PostDateLbl := "SLGI Cash G/L Entry".FieldCaption("Posting Date");
                    end;
                }
                textelement(AmountLbl)
                {

                    trigger OnBeforePassVariable()
                    begin
                        AmountLbl := "SLGI Cash G/L Entry".FieldCaption(Amount);
                    end;
                }
                textelement(D1)
                {

                    trigger OnBeforePassVariable()
                    begin
                        D1 := GetDimLabel(1);
                    end;
                }
                textelement(D2)
                {

                    trigger OnBeforePassVariable()
                    begin
                        D2 := GetDimLabel(2);
                    end;
                }
                textelement(D3)
                {

                    trigger OnBeforePassVariable()
                    begin
                        D3 := GetDimLabel(3);
                    end;
                }
                textelement(D4)
                {

                    trigger OnBeforePassVariable()
                    begin
                        D4 := GetDimLabel(4);
                    end;
                }
                textelement(D5)
                {

                    trigger OnBeforePassVariable()
                    begin
                        D5 := GetDimLabel(5);
                    end;
                }
                textelement(D6)
                {

                    trigger OnBeforePassVariable()
                    begin
                        D6 := GetDimLabel(6);
                    end;
                }
                textelement(D7)
                {

                    trigger OnBeforePassVariable()
                    begin
                        D7 := GetDimLabel(7);
                    end;
                }
                textelement(D8)
                {

                    trigger OnBeforePassVariable()
                    begin
                        D8 := GetDimLabel(8);
                    end;
                }
                textelement(D9)
                {

                    trigger OnBeforePassVariable()
                    begin
                        D9 := GetDimLabel(9);
                    end;
                }
                textelement(D10)
                {

                    trigger OnBeforePassVariable()
                    begin
                        D10 := GetDimLabel(10);
                    end;
                }
                textelement(D11)
                {

                    trigger OnBeforePassVariable()
                    begin
                        D11 := GetDimLabel(11);
                    end;
                }
                textelement(D12)
                {

                    trigger OnBeforePassVariable()
                    begin
                        D12 := GetDimLabel(12);
                    end;
                }
            }
            tableelement("SLGI Cash G/L Entry"; "SLGI Cash G/L Entry")
            {
                RequestFilterFields = "Posting Date";
                XmlName = 'CashLedgerEntry';
                fieldelement(AccountNo; "SLGI Cash G/L Entry"."G/L Account No.")
                {
                }
                textelement(AccName)
                {
                    trigger OnBeforePassVariable()
                    begin
                        AccName := AccountName;
                    end;
                }
                fieldelement(PostingDate; "SLGI Cash G/L Entry"."Posting Date")
                {
                }
                fieldelement(Amount; "SLGI Cash G/L Entry".Amount)
                {
                }
                textelement(Dims1)
                {

                    trigger OnBeforePassVariable()
                    begin
                        Dims1 := Dims[1];
                    end;
                }
                textelement(Dims2)
                {

                    trigger OnBeforePassVariable()
                    begin
                        Dims2 := Dims[2];
                    end;
                }
                textelement(Dims3)
                {

                    trigger OnBeforePassVariable()
                    begin
                        Dims3 := Dims[3];
                    end;
                }
                textelement(Dims4)
                {

                    trigger OnBeforePassVariable()
                    begin
                        Dims4 := Dims[4];
                    end;
                }
                textelement(Dims5)
                {

                    trigger OnBeforePassVariable()
                    begin
                        Dims5 := Dims[5];
                    end;
                }
                textelement(Dims6)
                {

                    trigger OnBeforePassVariable()
                    begin
                        Dims6 := Dims[6];
                    end;
                }
                textelement(Dims7)
                {

                    trigger OnBeforePassVariable()
                    begin
                        Dims7 := Dims[7];
                    end;
                }
                textelement(Dims8)
                {

                    trigger OnBeforePassVariable()
                    begin
                        Dims8 := Dims[8];
                    end;
                }
                textelement(Dims9)
                {

                    trigger OnBeforePassVariable()
                    begin
                        Dims9 := Dims[9];
                    end;
                }
                textelement(Dims10)
                {

                    trigger OnBeforePassVariable()
                    begin
                        Dims10 := Dims[10];
                    end;
                }
                textelement(Dims11)
                {

                    trigger OnBeforePassVariable()
                    begin
                        Dims11 := Dims[11];
                    end;
                }
                textelement(Dims12)
                {

                    trigger OnBeforePassVariable()
                    begin
                        Dims12 := Dims[12];
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    I: Integer;
                begin
                    GLAccount.Get("SLGI Cash G/L Entry"."G/L Account No.");
                    AccountName := GLAccount.Name;

                    DimMgmt.GetDimensionSet(DimSetEntry, "SLGI Cash G/L Entry"."Dimension Set ID");
                    Clear(Dims);
                    TempDimSet.Reset;
                    if DimSetEntry.FindSet then
                        repeat
                            TempDimSet.SetRange("Dimension Code", DimSetEntry."Dimension Code");
                            TempDimSet.FindSet;
                            Dims[TempDimSet."Dimension Set ID"] := DimSetEntry."Dimension Value Code";
                        until DimSetEntry.Next = 0;
                end;
            }
        }
    }


    trigger OnPreXmlPort()
    begin
        LoadDimensions;
    end;

    var
        DimMgmt: Codeunit DimensionManagement;
        DimSetEntry: Record "Dimension Set Entry" temporary;
        Dims: array[12] of Code[20];
        TempDimSet: Record "Dimension Set Entry" temporary;
        GLAccount: Record "G/L Account";
        AccountName: Text[100];

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
}

