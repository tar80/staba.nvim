---@alias expressions 'tabline'|'statusline'|'statuscolumn'|'fade'
---@alias listView 'tabs'|'buffers'
---@alias tabLine 'bufstats'|'parent'
---@alias tabLineBuffer 'devicon'|'nav_key'|'filename'|'modified'|'readonly'|'unopened'|'namestate'
---@alias lineNr 'LineNr'|'CursorLineNr'|'CursorLine'
---@alias shellSlash '/'|'\\'
---@alias statusColumn 'number'|'sign'|'fold'|'fold_ex'
---@alias NavID {[string]:integer}
---@alias BufInfo {tab:integer,buffer:integer,modified:integer,unopened:integer,cwd:string,format:string[]}
---@alias TablineTable {bufinfo:BufInfo,left:tabLine[],right:tabLine[],view:listView[],active:tabLineBuffer[],tabs:tabLineBuffer[],buffers:tabLineBuffer[]}
---@alias StatuslineSection {left:string[],middle:string[],right:string[]}
---@alias StatuslineTable {active:StatuslineSection,inactive:StatuslineSection}
---@alias StatusColumnTable {active:string,inactive:string}
---@alias IconDetail {chr:string,hlgroup:string}
---@alias IconsFold {open:string,close:string,blank:string}

---@generic T : string
---@alias CacheGet fun(self:Cache,name:T):self[T]

---@class Cache : CacheValue
---@field new fun(self,name:string,tbl:table)
---@field set fun(self,name:string,tbl:table)
---@field clear fun(self,name:string,value:any)
---@field remove fun(self,name:string,value:any)
---@field get CacheGet
---@field eq fun(self,name:string,actual:string,expect:string):boolean
---@field add_to_buflist fun(self,bufnr:integer)
---@field set_bufdata fun(self,bufnr:integer)

---@class CacheValue
---@field hlnames Options['hlnames']
---@field Buflist integer[]
---@field bufs Bufs
---@field icons Options['icons']
---@field frame Options['frame']
---@field sep Options['sep']
---@field ignore_filetypes Options['ignore_filetypes']
---@field bufdata BufData
---@field last_tabline string
---@field last_statusline_win integer

---@class Bufs
---@field name string
---@field devicon string

---@class BufData
---@field cwd string
---@field winid integer
---@field actual_bufnr integer
---@field alt_bufnr integer
---@field mark? {[integer]:{chr:string,id:integer}}

---@class Options
---@field enable_fade boolean
---@field enable_underline boolean
---@field enable_sign_marks boolean
---@field nav_keys string
---@field no_name string
---@field mode_line lineNr?
---@field ignore_filetypes {[expressions]:string[]}
---@field statuscolumn statusColumn[]
---@field statusline StatuslineTable
---@field tabline TablineTable
---@field frame Frame
---@field sep Sep
---@field icons Icons
---@field hlnames HlNames

---@class UserSpec
---@field enable_statuscolumn? boolean
---@field enable_statusline? boolean
---@field enable_tabline? boolean
---@field enable_underline? boolean
---@field enable_sign_marks? boolean
---@field enable_fade? boolean
---@field nav_keys? string
---@field no_name? string
---@field mode_line? lineNr?
---@field ignore_filetypes? [expressions]:string[]
---@field statuscolumn? statusColumn[]
---@field statusline? StatuslineTable
---@field tabline? TablineTable
---@field frame? Frame
---@field sep? Sep
---@field icons? Icons
---@field hlnames? HlNames

---@class Frame
---@field tabs_left string
---@field tabs_right string
---@field buffers_left string
---@field buffers_righ string
---@field statusline_l string
---@field statusline_r string

---@class Sep
---@field normal_left string
---@field normal_right string

---@class Icons
---@field logo string
---@field bar string
---@field bufinfo {tab:string,buffer:string,modified:string,unopened:string}
---@field fold IconsFold
---@field fileformat {dos:string[],mac:string[],unix:string[]}
---@field severity {Error:string[],Warn:string[],Hint:string[],Info:string[]}
---@field status {edit:string,lock:string,unlock:string,modify:string,nomodify:string,unopen:string,open:string}

---@class BufferStatus
---@field parent string
---@field name string
---@field no_name string
---@field bufnr integer
---@field buftype string
---@field modified integer
---@field readonly boolean
---@field unopened string?
---@field shellslash shellSlash
---@field nav_key string
---@field alternate? boolean
---@field mode? string[]

---@class HlNames
---@field mode_i string
---@field mode_v string
---@field mode_vb string
---@field mode_s string
---@field mode_r string
---@field mode_c string
---@field special string
---@field readonly string
---@field modified string
---@field status_nc string
---@field status_reverse string
---@field normal string
---@field normal_nc string
---@field normal_reverse string
---@field tabs string
---@field tabs_reverse string
---@field buffer string
---@field buffers_reverse string
