<#
.SYNOPSIS
    將 JUnit XML 測試報告轉換為 SonarQube Generic Test Execution Format
.DESCRIPTION
    根據 https://docs.sonarsource.com/sonarqube-server/10.6/analyzing-source-code/test-coverage/generic-test-data#generic-test-execution
.PARAMETER InputFile
    JUnit XML 報告檔案路徑
.PARAMETER OutputFile
    SonarQube Generic Format 輸出檔案路徑
.PARAMETER TestFilePath
    測試檔案的相對路徑 (例如: test/TestCalculator.cpp)
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputFile,
    
    [Parameter(Mandatory=$true)]
    [string]$TestFilePath
)

# 檢查輸入檔案是否存在
if (-not (Test-Path $InputFile)) {
    Write-Error "Input file not found: $InputFile"
    exit 1
}

# 讀取 JUnit XML
[xml]$junitXml = Get-Content $InputFile -Encoding UTF8

# 建立 SonarQube XML
$sonarXml = New-Object System.Xml.XmlDocument
$declaration = $sonarXml.CreateXmlDeclaration("1.0", "UTF-8", $null)
$sonarXml.AppendChild($declaration) | Out-Null

# 建立根節點 <testExecutions version="1">
$testExecutions = $sonarXml.CreateElement("testExecutions")
$testExecutions.SetAttribute("version", "1")
$sonarXml.AppendChild($testExecutions) | Out-Null

# 建立 <file> 節點
$fileElement = $sonarXml.CreateElement("file")
$fileElement.SetAttribute("path", $TestFilePath)
$testExecutions.AppendChild($fileElement) | Out-Null

# 處理 testsuites 或 testsuite 根節點
$testsuites = $junitXml.testsuites
if ($null -eq $testsuites) {
    $testsuites = $junitXml.testsuite
    if ($null -ne $testsuites) {
        # 單一 testsuite，包裝成陣列處理
        $testsuites = @($testsuites)
    }
} else {
    $testsuites = $junitXml.testsuites.testsuite
}

# 遍歷所有 testsuite
foreach ($testsuite in $testsuites) {
    foreach ($testcase in $testsuite.testcase) {
        # 建立 <testCase> 節點
        $testCaseElement = $sonarXml.CreateElement("testCase")
        
        # 設定 name 屬性 (使用 classname.name 格式或只用 name)
        $testName = $testcase.name
        if ($testcase.classname -and $testcase.classname -ne "") {
            $testName = "$($testcase.classname).$($testcase.name)"
        }
        $testCaseElement.SetAttribute("name", $testName)
        
        # 設定 duration 屬性 (JUnit 用秒，SonarQube 用毫秒)
        $durationMs = 0
        if ($testcase.time) {
            $durationMs = [math]::Round([double]$testcase.time * 1000)
        }
        $testCaseElement.SetAttribute("duration", $durationMs)
        
        # 處理測試結果狀態
        if ($testcase.failure) {
            $failureElement = $sonarXml.CreateElement("failure")
            if ($testcase.failure.message) {
                $failureElement.SetAttribute("message", $testcase.failure.message)
            }
            $testCaseElement.AppendChild($failureElement) | Out-Null
        }
        elseif ($testcase.error) {
            $errorElement = $sonarXml.CreateElement("error")
            if ($testcase.error.message) {
                $errorElement.SetAttribute("message", $testcase.error.message)
            }
            $testCaseElement.AppendChild($errorElement) | Out-Null
        }
        elseif ($testcase.skipped -or $testcase.skipped -eq "") {
            # 檢查是否有 skipped 子節點 (可能是空節點)
            if ($testcase.SelectSingleNode("skipped")) {
                $skippedElement = $sonarXml.CreateElement("skipped")
                if ($testcase.skipped.message) {
                    $skippedElement.SetAttribute("message", $testcase.skipped.message)
                }
                $testCaseElement.AppendChild($skippedElement) | Out-Null
            }
        }
        
        $fileElement.AppendChild($testCaseElement) | Out-Null
    }
}

# 確保輸出目錄存在
$outputDir = Split-Path $OutputFile -Parent
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# 儲存檔案
$sonarXml.Save($OutputFile)

Write-Host "Successfully converted JUnit XML to SonarQube Generic Format"
Write-Host "  Input:  $InputFile"
Write-Host "  Output: $OutputFile"

