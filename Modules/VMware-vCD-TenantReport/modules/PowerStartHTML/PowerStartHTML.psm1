class PowerStartHTML {
    [string]$PowerStartHtmlTemplate = "<html><head><meta charset=`"UTF-8`"/><title></title><style></style></head><body><div/></body></html>"
    [xml]$xmlDocument = $null
    $onLoadJS = $null
    $cssStyles= @{}
    $lastEl = $null
    $newEl = $null
    $indentedOutput = $false
    $bootstrapAtCompile = $false
    PowerStartHTML([string]$title) {
        $this.xmlDocument = $this.PowerStartHtmlTemplate
        $this.xmlDocument.html.head.title = $title
        $this.lastEl = $this.xmlDocument.html.body.ChildNodes[0]
        $this.onLoadJS = New-Object System.Collections.Generic.List[System.String]
    }
    [string] GetHtml() {
		$xmlclone = $this.xmlDocument.Clone()
        $csb = [System.Text.StringBuilder]::new()
        foreach ($cssStyle in $this.cssStyles.GetEnumerator()) {
            $null = $csb.AppendFormat("{0} {{ {1} }}",$cssStyle.Name,$cssStyle.Value)
        }
        $this.xmlDocument.html.head.style = $csb.toString()
        $this.AddBootStrapAtCompile()
        if($this.onLoadJS.Count -gt 0) {
            $this.onLoadJs.Insert(0,"`r`n`$(document).ready(function() {")
            $this.onLoadJs.Add("})`r`n")
            $el = $this.xmlDocument.CreateElement("script")
            $el.AppendChild($this.xmlDocument.CreateTextNode([System.String]::Join("`r`n",$this.onLoadJs)))
            $this.xmlDocument.html.body.AppendChild($el)
        }
        $ms = [System.IO.MemoryStream]::new()
        $xmlWriter = [System.Xml.XmlTextWriter]::new($ms,[System.Text.Encoding]::UTF8)
        if($this.indentedOutput) {
            $xmlWriter.Formatting = [System.Xml.Formatting]::Indented
        }
        $this.xmlDocument.WriteContentTo($xmlWriter)
        $xmlWriter.Flush()
        $ms.Flush()
		#make sure that everytime we do gethtml we keep it clean
		$this.xmlDocument = $xmlclone
        $ms.Position = 0;
        $sr = [System.IO.StreamReader]::new($ms);
        return  ("<!DOCTYPE html>{0}`r`n" -f $sr.ReadToEnd())
    }
    Save($path) {
        $this.GetHtml() | Set-Content -path $path -Encoding UTF8
    }
	
    AddAttr($el,$name,$value) {
        $attr = $this.xmlDocument.CreateAttribute($name)
        $attr.Value = $value
        $el.Attributes.Append($attr)
    }

    AddAttrs($el,$dict) {
        foreach($a in $dict.GetEnumerator()) {
            $this.AddAttr($el,$a.Name,$a.Value)
        }
    }
    [PowerStartHTML] AddBootStrap() {
        $this.bootstrapAtCompile = $true
        return $this
    }
    AddJSScript($href,$integrity) {
        $el = $this.xmlDocument.CreateElement("script")
        $attrs = @{
            "src"="$href";
            "integrity"="$integrity";
            "crossorigin"="anonymous"
        }
        $this.AddAttrs($el,$attrs)
        $el.AppendChild($this.xmlDocument.CreateTextNode(""))
        $this.xmlDocument.html.body.AppendChild($el)   
    }
    AddBootStrapAtCompile() { #Bootstrap script needs to be added at the end
        if($this.bootstrapAtCompile) {
            $el = $this.xmlDocument.CreateElement("link")
            $attrs = @{
                "rel"="stylesheet";
                "href"='https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0-beta/css/bootstrap.min.css';
                "integrity"="sha384-/Y6pD6FV/Vv2HJnA6t+vslU6fwYXjCFtcEpHbNJ0lyAFsXTsjBbfaDjzALeQsN6M";
                "crossorigin"="anonymous"
            }
            $this.AddAttrs($el,$attrs)
            $el.AppendChild($this.xmlDocument.CreateTextNode(""))
            $this.xmlDocument.html.head.AppendChild($el)
            $this.AddJSScript('https://code.jquery.com/jquery-3.2.1.slim.min.js',"sha384-KJ3o2DKtIkvYIK3UENzmM7KCkRr/rE9/Qpg6aAZGJwFDMVNA/GpGFF93hXpG5KkN")
            $this.AddJSScript('https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.11.0/umd/popper.min.js',"sha384-b/U6ypiBEHpOf/4+1nzFpr53nxSS+GLCkfwBdFNTxtclqqenISfwAzpKaMNFNmj4")
            $this.AddJSScript('https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0-beta/js/bootstrap.min.js',"sha384-h0AbiXch4ZDo7tp9hKZ4TsHbi047NrKGLO3SEJAg45jXxnGIfYzk4Si90RDIqNm1")
        }
    }
     [PowerStartHTML]  AddContainerAttrToMain() {
        $this.AddAttr($this.xmlDocument.html.body.ChildNodes[0],"class","container")
        return $this
    }
    [PowerStartHTML] Append($elType = "table",$className=$null,[string]$text=$null) {
        $el = $this.xmlDocument.CreateElement($elType)
        if($text -ne $null) {
            $el.AppendChild($this.xmlDocument.CreateTextNode($text))
        } 
        if($className -ne $null) {
            $this.AddAttr($el,"class",$className)
        }
        $this.lastEl.AppendChild($el)
        $this.newEl = $el

        return $this
    }
    [PowerStartHTML] Append($elType = "table",$className=$null) { return $this.Append($elType,$className,$null) }
    [PowerStartHTML] Append($elType = "table") { return $this.Append($elType,$null,$null) }
    [PowerStartHTML] Add($elType = "table",$className=$null,[string]$text=$null) {
        $this.Append($elType,$className,$text)
        $this.lastEl = $this.newEl
        return $this
    }
    [PowerStartHTML] Add($elType = "table",$className=$null) { return $this.Add($elType,$className,$null) }
    [PowerStartHTML] Add($elType = "table") { return $this.Add($elType,$null,$null) }
    [PowerStartHTML] Main() {
        $this.lastEl = $this.xmlDocument.html.body.ChildNodes[0];
        return $this
    }
    [PowerStartHTML] Up() {
        $this.lastEl = $this.lastEl.ParentNode;
        return $this
    }
    N() {}
}
class PowerStartHTMLPassThroughLine {
    $object;$cells
    PowerStartHTMLPassThroughLine($object) {
        $this.object = $object; 
        $this.cells = new-object System.Collections.HashTable;
    }
}
class PowerStartHTMLPassThroughElement {
    $name;$text;$element;$id
    PowerStartHTMLPassThroughElement($name,$text,$element,$id) {
        $this.name = $name; $this.text = $text; $this.element = $element;$this.id = $id
    }
}
function New-PowerStartHTML {
	param(
		[Parameter(Mandatory=$true)][string]$title,
        [switch]$nobootstrap=$false
	)
    $pshtml = (new-object PowerStartHTML($title))
    if(-not $nobootstrap) {
        $pshtml.AddBootStrap().AddContainerAttrToMain().N()
    }
    return $pshtml
}
function Add-PowerStartHTMLTable {
    param(
         [Parameter(Mandatory=$True,ValueFromPipeline=$True)]$object,
         [PowerStartHTML]$psHtml,
         [string]$tableTitle = $null,
         [string]$tableClass = $null,
         [string]$idOverride = $(if($tableTitle -ne $null) {($tableTitle.toLower() -replace "[^a-z0-9]","-") }),
         [switch]$passthroughTable = $false,
		 [switch]$noheaders = $false
    )
    begin {
        if($tableTitle -ne $null) {
            $psHtml.Main().Append("h1",$null,$tableTitle).N()
            if($idOverride -ne $null) {
                $psHtml.AddAttr($psHtml.newEl,"id","header-$idOverride")
            }   
        } 
        $psHtml.Main().Add("table").N()
        [int]$r = 0
        [int]$c = 0
        if($idOverride -ne $null) {
           $psHtml.AddAttr($psHtml.newEl,"id","table-$idOverride")
        }      
        if($tableClass -ne $null) {
           $psHtml.AddAttr($psHtml.newEl,"class",$tableClass)
        } 
		[bool]$isFirst = $true
    }
    process {
        $c = 0
		
		$props = $object | Get-Member -Type Properties
		if(-not $noheaders -and $isFirst) {
			$psHtml.Add("tr").N()
			if($idOverride -ne $null) {
				$psHtml.AddAttr($psHtml.newEl,"id","table-$idOverride-trh")
			}   
			$props | % {
				$n = $_.Name;
				$psHtml.Append("th",$null,$n).N()
				if($idOverride -ne $null) {
					$cellid = "table-$idOverride-td-$r-$c"
					$psHtml.AddAttr($psHtml.newEl,"id",$cellid)
				}   
				$c++
			}
			$c = 0
			$psHtml.Up().N()
		}

        $psHtml.Add("tr").N()
        if($idOverride -ne $null) {
            $psHtml.AddAttr($psHtml.newEl,"id","table-$idOverride-tr-$r")
        }   
        $pstableln = [PowerStartHTMLPassThroughLine]::new($object)
		
        $props | % {
            $n = $_.Name;
            $psHtml.Append("td",$null,$object."$n").N()
            $cellid = $null
            if($idOverride -ne $null) {
                $cellid = "table-$idOverride-td-$r-$c"
                $psHtml.AddAttr($psHtml.newEl,"id",$cellid)
            }      
            if($passthroughTable) {
                $pstableln.cells.Add($n,[PowerStartHTMLPassThroughElement]::new($n,($object."$n"),$psHtml.newEl,$cellid))
            }
            
            $c++
        }
        if($passthroughTable) {
            $pstableln
        }
        $psHtml.Up().N()
		$isFirst = $false
        $r++
    }
    end { 
    }
}


Export-ModuleMember -Function @('New-PowerStartHTML','Add-PowerStartHTMLTable')



