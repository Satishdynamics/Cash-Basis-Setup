report 50054 "SLGI Cash Trial Balance Spread"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Reports/Trial Balance, Spread Periods.rdl';
    Caption = 'Cash Basis Trial Balance, Spread Periods';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Account Type", "Date Filter", "Global Dimension 1 Filter", "Global Dimension 2 Filter", "Budget Filter";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyInfoName; CompanyInformation.Name)
            {
            }
            column(AmountText; AmountText)
            {
            }
            column(PrintToExcel; false)
            {
            }
            column(UseAddRptCurr; UseAddRptCurr)
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(GLAccountFilter; GLAccountFilter)
            {
            }
            column(NoofBlankLines_GLAccount; "G/L Account"."No. of Blank Lines")
            {
            }
            column(PageHeaderCondition; ((((LineType = LineType::"9-Point") or (LineType = LineType::"9-Point Rounded")))))
            {
            }
            column(SubTitle; SubTitle)
            {
            }
            column(GLAcTblCaptionGLAccountFilter; "G/L Account".TableCaption + ': ' + GLAccountFilter)
            {
            }
            column(ColumnHead1; ColumnHead[1])
            {
            }
            column(ColumnHead2; ColumnHead[2])
            {
            }
            column(ConditionGLAccountHdr6; ((LineType = LineType::"9-Point")))
            {
            }
            column(ColumnHead3; ColumnHead[3])
            {
            }
            column(ConditionGLAccountHdr7; ((LineType = LineType::"9-Point Rounded")))
            {
            }
            column(ColumnHead4; ColumnHead[4])
            {
            }
            column(ConditionGLAccountHdr8; ((LineType = LineType::"8-Point")))
            {
            }
            column(ConditionGLAccountHdr9; ((LineType = LineType::"8-Point Rounded")))
            {
            }
            column(ColumnHead5; ColumnHead[5])
            {
            }
            column(ColumnHead6; ColumnHead[6])
            {
            }
            column(ConditionGLAccountHdr10; ((LineType = LineType::"7-Point")))
            {
            }
            column(ColumnHead7; ColumnHead[7])
            {
            }
            column(ColumnHead8; ColumnHead[8])
            {
            }
            column(ConditionGLAccountHdr11; ((LineType = LineType::"7-Point Rounded")))
            {
            }
            column(No_GLAccount; "No.")
            {
            }
            column(TrialBalanceCaption; TrialBalanceCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(NoCaption_GLAccount; FieldCaption("No."))
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            dataitem(BlankLineCounter; Integer)
            {
                DataItemTableView = sorting(Number);
                PrintOnlyIfDetail = true;

                trigger OnPreDataItem();
                begin
                    SetRange(Number, 1, "G/L Account"."No. of Blank Lines");
                end;
            }
            dataitem(DataItem5444; Integer)
            {
                DataItemTableView = sorting(Number)
                                    where(Number = const(1));
                column(DescriptionLine1; DescriptionLine1)
                {
                }
                column(IntegerBody1Condition; (((LineType = LineType::"9-Point") or (LineType = LineType::"9-Point Rounded")) and (DescriptionLine1 <> '')))
                {
                }
                column(DescriptionLine2; DescriptionLine2)
                {
                }
                column(GLAccountNo; "G/L Account"."No.")
                {
                }
                column(IntegerBody2Condition; (((LineType = LineType::"9-Point") or (LineType = LineType::"9-Point Rounded")) and ("G/L Account"."Account Type" <> "G/L Account"."Account Type"::Posting) and ("G/L Account".Totaling = '')))
                {
                }
                column(IntegerBody3Condition; (((LineType = LineType::"8-Point") or (LineType = LineType::"8-Point Rounded")) and (DescriptionLine1 <> '')))
                {
                }
                column(IntegerBody4Condition; (((LineType = LineType::"8-Point") or (LineType = LineType::"8-Point Rounded")) and ("G/L Account"."Account Type" <> "G/L Account"."Account Type"::Posting) and ("G/L Account".Totaling = '')))
                {
                }
                column(IntegerBody5Condition; (((LineType = LineType::"7-Point") or (LineType = LineType::"7-Point Rounded")) and (DescriptionLine1 <> '')))
                {
                }
                column(IntegerBody6Condition; (((LineType = LineType::"7-Point") or (LineType = LineType::"7-Point Rounded")) and ("G/L Account"."Account Type" <> "G/L Account"."Account Type"::Posting) and ("G/L Account".Totaling = '')))
                {
                }
                column(PrintAmt1; PrintAmount[1])
                {
                }
                column(PrintAmt2; PrintAmount[2])
                {
                }
                column(IntegerBody7Condition; ((LineType = LineType::"9-Point") and NumbersToPrint))
                {
                }
                column(PrintAmt3; PrintAmount[3])
                {
                }
                column(IntegerBody8Condition; ((LineType = LineType::"9-Point Rounded") and NumbersToPrint))
                {
                }
                column(PrintAmt4; PrintAmount[4])
                {
                }
                column(IntegerBody9Condition; ((LineType = LineType::"8-Point") and NumbersToPrint))
                {
                }
                column(IntegerBody10Condition; ((LineType = LineType::"8-Point Rounded") and NumbersToPrint))
                {
                }
                column(PrintAmt5; PrintAmount[5])
                {
                }
                column(PrintAmt6; PrintAmount[6])
                {
                }
                column(IntegerBody11Condition; ((LineType = LineType::"7-Point") and NumbersToPrint))
                {
                }
                column(PrintAmt7; PrintAmount[7])
                {
                }
                column(PrintAmt8; PrintAmount[8])
                {
                }
                column(IntegerBody12Condition; ((LineType = LineType::"7-Point Rounded") and NumbersToPrint))
                {
                }

                trigger OnAfterGetRecord();
                begin
                end;

                trigger OnPostDataItem();
                begin
                    if "G/L Account"."New Page" then
                        PageGroupNo := PageGroupNo + 1;
                end;
            }

            trigger OnAfterGetRecord();
            begin
                Clear(DescriptionLine2);
                Clear(DescriptionLine1);
                Clear(WorkAmount);
                Clear(PrintAmount);
                if ("Account Type" = "Account Type"::Posting) or
                   (Totaling <> '')
                then
                    for i := 1 to MaxColumns do
                        if ColumnFilter[i] <> '' then begin
                            SetFilter("Date Filter", ColumnFilter[i]);
                            case AmountType of
                                AmountType::"Actual Change":
                                    begin
                                        CalcFields("SLGI CSH Net Change Cash");
                                        WorkAmount[i] := "SLGI CSH Net Change Cash";
                                    end;
                                AmountType::"Actual Balance":
                                    begin
                                        CalcFields("SLGI CSH Balance at Date Cash");
                                        WorkAmount[i] := "SLGI CSH Balance at Date Cash";
                                    end;
                                AmountType::"Budget Change":
                                    begin
                                        CalcFields("Budgeted Amount");
                                        WorkAmount[i] := "Budgeted Amount";
                                    end;
                                AmountType::"Budget Balance":
                                    begin
                                        CalcFields("Budget at Date");
                                        WorkAmount[i] := "Budget at Date";
                                    end;
                            end;
                        end;

                /* Handle the description */
                DescriptionLine2 := PadStr('', Indentation) + Name;
                ParagraphHandling.SplitPrintLine(DescriptionLine2, DescriptionLine1, MaxDescWidth, PointSize);
                /* Format the numbers (if any) */
                if NumbersToPrint then begin
                    /* format the individual numbers, first numerically */
                    for i := 1 to MaxColumns do
                        case RoundTo of
                            RoundTo::Dollars:
                                WorkAmount[i] := Round(WorkAmount[i], 1);
                            RoundTo::Thousands:
                                WorkAmount[i] := Round(WorkAmount[i] / 1000, 1);
                            RoundTo::Pennies:
                                WorkAmount[i] := Round(WorkAmount[i], 0.01);
                        end;

                    /* now format the strings */
                    for i := 1 to MaxColumns do
                        if WorkAmount[i] <> 0 then begin
                            PrintAmount[i] := Format(WorkAmount[i]);
                            if RoundTo = RoundTo::Pennies then begin   // add decimal places if necessary
                                j := StrPos(PrintAmount[i], '.');
                                if j = 0 then
                                    PrintAmount[i] := PrintAmount[i] + '.00'
                                else
                                    if j = StrLen(PrintAmount[i]) - 1 then
                                        PrintAmount[i] := PrintAmount[i] + '0';
                            end;
                        end;
                end;

            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(SelectReportAmount; AmountType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Select Report Amount';
                        OptionCaption = 'Actual Change,Budget Change,Last Year Change,Actual Balance,Budget Balance,Last Year Balance';
                        ToolTip = 'Specifies that the report includes amounts.';
                    }
                    field(RoundTo; RoundTo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = '"Round to "';
                        OptionCaption = 'Pennies,Dollars,Thousands';
                        ToolTip = 'Specifies if you want the results in the report to be rounded to the nearest penny (hundredth of a unit), dollar (unit), or thousand dollars (units). The results are in US dollars, unless you select the Use Additional Reporting Currency check box.';
                    }
                    field(PeriodCalc; PeriodCalc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Time Division';
                        DateFormula = true;
                        ToolTip = 'Specifies how periods are shown in the report. Leave the field blank to show by your accounting periods. Enter, for example, 10D to show by divisions of ten days. The range of dates will expand if needed to cover complete periods of time.';
                    }
                    field(SkipZeros; SkipZeros)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Skip Accounts with all zero Amounts';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want the report to be generated with all of the accounts, including those with zero amounts. Otherwise, those accounts will be excluded.';
                    }
                    field(UseAdditionalReportingCurrency; UseAddRptCurr)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Use Additional Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want all amounts to be printed by using the additional reporting currency. If you do not select the check box, then all amounts will be printed in US dollars.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport();
    begin
    end;

    trigger OnPreReport();
    begin
        CompanyInformation.Get;
        /* set up the date ranges */
        FromDate := "G/L Account".GetRangeMin("Date Filter");
        ToDate := "G/L Account".GetRangeMax("Date Filter");
        PriorFromDate := CalcDate('<-1Y>', FromDate);
        PriorToDate := CalcDate('<-1Y>', ToDate);
        "G/L Account".SetRange("Date Filter");     // since these are in the titles, they
        GLAccountFilter := "G/L Account".GetFilters; // do not have to be in the filter string
        /* Calculate the Period Columns */
        if (AmountType = AmountType::"Last Year Change") or
           (AmountType = AmountType::"Last Year Balance")
        then begin
            if AmountType = AmountType::"Last Year Balance" then
                AmountType := AmountType::"Actual Balance"
            else
                AmountType := AmountType::"Actual Change";
            FromDate := PriorFromDate;
            ToDate := PriorToDate;
        end;
        if StrPos(PeriodCalc, 'P') <> 0 then
            PeriodCalc := '';   // null means we are using periods
        NumColumns := 0;
        if PeriodCalc = '' then begin  // extend date range to beginning of period
            AccountingPeriod.SetFilter("Starting Date", '..%1', FromDate);
            AccountingPeriod.Find('+');
            FromDate := AccountingPeriod."Starting Date";
            AccountingPeriod.SetRange("Starting Date");
        end;
        PriorToDate := ToDate;  // save original ending point
        Clear(ColumnFilter);
        repeat
            PriorFromDate := FromDate;
            if PeriodCalc = '' then begin
                if AccountingPeriod.Next = 0 then
                    FromDate := CalcDate('<M>', PriorFromDate)
                else
                    FromDate := AccountingPeriod."Starting Date"
            end else
                FromDate := CalcDate(PeriodCalc, PriorFromDate);
            ToDate := FromDate - 1;
            "G/L Account".SetRange("Date Filter", PriorFromDate, ToDate);
            NumColumns := NumColumns + 1;
            ColumnFilter[NumColumns] := "G/L Account".GetFilter("Date Filter");
        until (NumColumns = MaxColumns) or (FromDate > PriorToDate);
        /* Set up format-dependent variables */
        case NumColumns of
            0:
                Error(Text000);
            1, 2:
                if RoundTo = RoundTo::Pennies then
                    LineType := LineType::"9-Point"
                else
                    LineType := LineType::"9-Point Rounded";
            3:
                if RoundTo = RoundTo::Pennies then
                    LineType := LineType::"8-Point"
                else
                    LineType := LineType::"9-Point Rounded";
            4:
                if RoundTo = RoundTo::Pennies then
                    LineType := LineType::"8-Point"
                else
                    LineType := LineType::"8-Point Rounded";
            5, 6:
                if RoundTo = RoundTo::Pennies then
                    LineType := LineType::"7-Point"
                else
                    LineType := LineType::"7-Point Rounded";
            7, 8:
                if RoundTo = RoundTo::Pennies then
                    Error(Text001)
                else
                    LineType := LineType::"7-Point Rounded";
            9 .. ArrayLen(WorkAmount):
                Error(Text010);
            else
                Error(Text002, ArrayLen(WorkAmount));
        end;
        if RoundTo = RoundTo::Pennies then
            ExcelAmtFormat := '#,##0.00'
        else
            ExcelAmtFormat := '#,##0';

        case LineType of
            LineType::"9-Point", LineType::"9-Point Rounded":
                begin
                    MaxDescWidth := 67;
                    PointSize := 9;
                end;
            LineType::"8-Point", LineType::"8-Point Rounded":
                begin
                    MaxDescWidth := 52;
                    PointSize := 8;
                end;
            LineType::"7-Point", LineType::"7-Point Rounded":
                begin
                    MaxDescWidth := 33;
                    PointSize := 7;
                end;
            else
                Error(Text003);
        end;
        /* set up header texts */
        Clear(AmountText);
        Clear(ColumnHead);
        /* Amount Type Headings */
        case AmountType of
            AmountType::"Actual Change":
                AmountText := Text004;
            AmountType::"Budget Change":
                AmountText := Text005;
            AmountType::"Actual Balance":
                AmountText := Text006;
            AmountType::"Budget Balance":
                AmountText := Text007;
        end;
        if UseAddRptCurr then begin
            GLSetup.Get;
            Currency.Get(GLSetup."Additional Reporting Currency");
            SubTitle := StrSubstNo(Text008, Currency.Description);
        end;

        /* Column Headings */
        for i := 1 to MaxColumns do
            if ColumnFilter[i] <> '' then begin
                "G/L Account".SetFilter("Date Filter", ColumnFilter[i]);
                ColumnHead[i] := Format("G/L Account".GetRangeMin("Date Filter")) +
                  ' thru ' +
                  Format("G/L Account".GetRangeMax("Date Filter"));
            end;
        if RoundTo = RoundTo::Thousands then
            for i := 1 to MaxColumns do
                if ColumnHead[i] <> '' then
                    ColumnHead[i] := ColumnHead[i] + Text009;
    end;

    var
        CompanyInformation: Record "Company Information";
        AccountingPeriod: Record "Accounting Period";
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        ExcelBuf: Record "Excel Buffer" temporary;
        ParagraphHandling: Codeunit "Paragraph Handling";
        AmountText: Text[120];
        GLAccountFilter: Text;
        ColumnFilter: array[250] of Text;
        SubTitle: Text[132];
        SkipZeros: Boolean;
        UseAddRptCurr: Boolean;
        PeriodCalc: Code[20];
        AmountType: Option "Actual Change","Budget Change","Last Year Change","Actual Balance","Budget Balance","Last Year Balance";
        RoundTo: Option Pennies,Dollars,Thousands;
        LineType: Option "9-Point","9-Point Rounded","8-Point","8-Point Rounded","7-Point","7-Point Rounded";
        ColumnHead: array[250] of Text[50];
        PrintAmount: array[250] of Text[30];
        WorkAmount: array[250] of Decimal;
        FromDate: Date;
        ToDate: Date;
        PriorFromDate: Date;
        PriorToDate: Date;
        DescriptionLine2: Text[80];
        DescriptionLine1: Text[80];
        MaxDescWidth: Integer;
        PointSize: Integer;
        j: Integer;
        i: Integer;
        NumColumns: Integer;
        Text000: Label 'No Periods selected. Try another Date Filter or Time Division.';
        Text001: Label 'If you want more than 6 Periods you must round to Dollars or Thousands.';
        Text002: Label 'You must select no more than %1 Periods. Try another Date Filter or Time Division.';
        Text003: Label 'Program Bug.';
        Text004: Label 'Net Changes';
        Text005: Label 'Budgeted Changes';
        Text006: Label 'Balances';
        Text007: Label 'Budgeted Balances';
        Text008: Label 'Amounts are in %1';
        Text009: Label '" (Thousands)"';
        ExcelAmtFormat: Text[30];
        Text010: Label 'You must select no more than 8 Periods for printing. Try another Date Filter or Time Division, or use the Print To Excel option.';
        Text101: Label 'Data';
        Text102: Label 'Cash Trial Balance';
        Text103: Label 'Company Name';
        Text104: Label 'Report No.';
        Text105: Label 'Report Name';
        Text106: Label 'User ID';
        Text107: Label 'Date / Time';
        Text108: Label 'G/L Account Filters';
        Text109: Label 'Sub-Title';
        Text110: Label 'Amounts are in';
        Text111: Label 'our Functional Currency';
        PageGroupNo: Integer;
        TrialBalanceCaptionLbl: Label 'Cash Trial Balance';
        PageCaptionLbl: Label 'Page';
        NameCaptionLbl: Label 'Name';

    procedure NumbersToPrint(): Boolean;
    var
        i: Integer;
    begin
        /* Returns whether any numbers are available to be printed this time */
        if ("G/L Account"."Account Type" <> "G/L Account"."Account Type"::Posting) and
           ("G/L Account".Totaling = '')
        then
            exit(false);
        if ("G/L Account"."Account Type" = "G/L Account"."Account Type"::Posting) and SkipZeros then begin
            for i := 1 to ArrayLen(WorkAmount) do
                if WorkAmount[i] <> 0.0 then
                    exit(true);
            exit(false);
        end;
        exit(true);

    end;

    local procedure MaxColumns(): Integer;
    begin
        exit(8);
    end;
}

