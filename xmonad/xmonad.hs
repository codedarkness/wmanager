--  ____             _                         ____          _
-- |  _ \  __ _ _ __| | ___ __   ___  ___ ___ / ___|___   __| | ___
-- | | | |/ _' | '__| |/ / '_ \ / _ \/ __/ __| |   / _ \ / _' |/ _ \
-- | |_| | (_| | |  |   <| | | |  __/\__ \__ \ |__| (_) | (_| |  __/
-- |____/ \__,_|_|  |_|\_\_| |_|\___||___/___/\____\___/ \__,_|\___|
-- -----------------------------------------------------------------
-- https://darkncesscode.xyz
-- https://github.com/codedarkness
-- -----------------------------------------------------------------

import System.IO (Handle, hPutStrLn)
import System.Exit

import XMonad
import XMonad.Hooks.SetWMName
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.Minimize
import XMonad.Hooks.ManageHelpers(doFullFloat, doCenterFloat, isFullscreen, isDialog)
import XMonad.Config.Desktop
import XMonad.Config.Azerty
import XMonad.Util.Run(spawnPipe)
import XMonad.Actions.SpawnOn
import XMonad.Util.EZConfig (additionalKeys, additionalMouseBindings)
import XMonad.Actions.CycleWS
import XMonad.Hooks.UrgencyHook

import XMonad.Layout.Spacing
import XMonad.Layout.Gaps
import XMonad.Layout.ResizableTile
import XMonad.Layout.NoBorders
import XMonad.Layout.Fullscreen (fullscreenFull)
import XMonad.Layout.Cross(simpleCross)
import XMonad.Layout.Spiral(spiral)
import XMonad.Layout.Grid
import XMonad.Layout.ThreeColumns
import XMonad.Layout.MultiToggle
import XMonad.Layout.MultiToggle.Instances
import XMonad.Layout.IndependentScreens
import XMonad.Layout.Minimize
import XMonad.Layout.CenteredMaster(centerMaster)

import Graphics.X11.ExtraTypes.XF86
import Control.Monad (liftM2)

import qualified Codec.Binary.UTF8.String as UTF8
import qualified XMonad.Actions.DynamicWorkspaceOrder as DO
import qualified System.IO
import qualified XMonad.StackSet as W
import qualified Data.Map as M
import qualified Data.ByteString as B

myModMask  = mod4Mask
myTerminal = "st"

mydefaults = def {
          normalBorderColor   = "#2F3D44"
        , focusedBorderColor  = "#556064"
        , focusFollowsMouse   = True
        , mouseBindings       = myMouseBindings
        , workspaces          = myWorkspaces
        , keys                = myKeys
        , modMask             = myModMask
        , borderWidth         = 1
        , layoutHook          = myLayoutHook
        , startupHook         = myStartupHook
        , manageHook          = myManageHook
        , handleEventHook     = fullscreenEventHook <+> docksEventHook <+> minimizeEventHook
        }

-- Autostart
myStartupHook = do
    spawn "$HOME/.xmonad/autostart.sh"
    setWMName "LG3D"

encodeCChar = map fromIntegral . B.unpack

myTitleColor = "#81A1C1" -- color of window title
myTitleLength = 80 -- truncate window title to this length
myCurrentWSColor = "#1F618D" -- color of active workspace
myVisibleWSColor = "#839192" -- color of inactive workspace
myUrgentWSColor = "#C45500" -- color of workspace with 'urgent' window
myHiddenNoWindowsWSColor = "#839192"

myLayoutHook = spacingRaw True (Border 5 5 5 5) True (Border 5 5 5 5) True $ gaps [(U,30), (D,5), (R,5), (L,5)]
               $ avoidStruts
               $ mkToggle (NBFULL ?? NOBORDERS ?? EOT)
              -- $ smartBorders
               $ tiled ||| Grid ||| spiral (6/7) ||| ThreeColMid 1 (3/100) (1/2) ||| noBorders Full
                    where
                    tiled   = Tall nmaster delta ratio
                    nmaster = 1
                    delta   = 3/100
                    ratio   = 1/2

--WORKSPACES
xmobarEscape = concatMap doubleLts
    where doubleLts '<' = "<<"
          doubleLts x = [x]

myWorkspaces :: [String]
myWorkspaces = clickable . (map xmobarEscape) $ ["DEV","WWW","SYS","GFX","DOC","CHT","EDT","TXT","CLI"]
    where
               clickable l = [ "<action=xdotool key super+" ++ show (n) ++ ">" ++ ws ++ "</action>" | (i,ws) <- zip [1..9] l, let n = i ]

-- window manipulations
myManageHook = composeAll . concat $
    [ [isDialog --> doCenterFloat]
    , [className =? c --> doCenterFloat | c <- myCFloats]
    , [title =? t --> doFloat | t <- myTFloats]
    , [resource =? r --> doFloat | r <- myRFloats]
    , [resource =? i --> doIgnore | i <- myIgnores]
    ]
    where
    myCFloats = ["Arandr", "Lxappearance", "Galculator", "mpv", "Nitrogen"]
    myTFloats = ["Downloads", "Save As..."]
    myRFloats = []
    myIgnores = ["desktop_window"]

-- keys config

myKeys conf@(XConfig {XMonad.modMask = modMask}) = M.fromList $

  -- Keybindings

  [ ((modMask, xK_Return), spawn $ myTerminal )
  , ((modMask, xK_Escape), spawn $ "xkill" )
  , ((modMask, xK_f), sendMessage $ Toggle NBFULL)
  , ((modMask, xK_q), kill )

  -- SUPER + SHIFT KEYS

  , ((modMask .|. shiftMask , xK_Return ), spawn $ myTerminal)
  , ((modMask .|. shiftMask , xK_r ), spawn $ "xmonad --recompile && xmonad --restart")
  , ((modMask .|. shiftMask , xK_q ), kill)
  , ((modMask .|. shiftMask , xK_x ), io (exitWith ExitSuccess))

  -- ALT + ... KEYS

  , ((mod1Mask, xK_r), spawn $ "xmonad --restart" )
  , ((mod1Mask, xK_F3), spawn $ "xfce4-appfinder" )

  -- My Keybindings

  , ((modMask, xK_F2), spawn $ "brave" )
  , ((modMask, xK_F3), spawn $ "pcmanfm" )
  , ((modMask, xK_F11), spawn $ "$HOME/.xmonad/nmcli/networkmanager_dmenu" )
  , ((modMask, xK_F12), spawn $ "blurlock" )

  , ((modMask, xK_r), spawn (myTerminal ++ " -e ranger" ))
  , ((modMask, xK_v), spawn (myTerminal ++ " -e vim" ))
  , ((modMask, xK_p), spawn (myTerminal ++ " -e pyradio"))
  , ((modMask, xK_c), spawn (myTerminal ++ " -e calcurse"))
  , ((modMask, xK_w), spawn $ "brave" )

  , ((modMask .|. shiftMask , xK_o ), spawn $ "dmenu_run")
  , ((modMask, xK_0), spawn $ "$HOME/.xmonad/sysact.sh")
  , ((modMask, xK_o), spawn $ "$HOME/.xmonad/dmenu-programs.sh" )

  , ((0, xK_Print), spawn $ "dc-scrot -d")

  --MULTIMEDIA KEYS

  , ((0, xF86XK_AudioMute), spawn $ "amixer -q set Master toggle")
  , ((0, xF86XK_AudioLowerVolume), spawn $ "amixer -q set Master 5%-")
  , ((0, xF86XK_AudioRaiseVolume), spawn $ "amixer -q set Master 5%+")

  , ((0, xF86XK_MonBrightnessUp),  spawn $ "xbacklight -inc 5")
  , ((0, xF86XK_MonBrightnessDown), spawn $ "xbacklight -dec 5")

  , ((0, xF86XK_AudioPlay), spawn $ "playerctl play-pause")
  , ((0, xF86XK_AudioNext), spawn $ "playerctl next")
  , ((0, xF86XK_AudioPrev), spawn $ "playerctl previous")
  , ((0, xF86XK_AudioStop), spawn $ "playerctl stop")


  --  XMONAD LAYOUT KEYS

  -- Cycle through the available layout algorithms.
  , ((modMask, xK_space), sendMessage NextLayout)

  --Focus selected desktop
  , ((mod1Mask, xK_Tab), nextWS)

  --Focus selected desktop
  , ((modMask, xK_Tab), nextWS)

  -- Move focus to the next window.
  , ((modMask, xK_j), windows W.focusDown)

  -- Move focus to the previous window.
  , ((modMask, xK_k), windows W.focusUp  )

  -- Move focus to the master window.
  , ((modMask .|. shiftMask, xK_m), windows W.focusMaster  )

  -- Swap the focused window with the next window.
  , ((modMask .|. shiftMask, xK_j), windows W.swapDown  )

  -- Swap the focused window with the previous window.
  , ((modMask .|. shiftMask, xK_k), windows W.swapUp    )

  -- Shrink the master area.
  , ((controlMask .|. shiftMask , xK_h), sendMessage Shrink)

  -- Expand the master area.
  , ((controlMask .|. shiftMask , xK_l), sendMessage Expand)

  -- Push window back into tiling.
  , ((controlMask .|. shiftMask , xK_t), withFocused $ windows . W.sink)

  ]
  ++

  -- mod-[1..9], Switch to workspace N
  -- mod-shift-[1..9], Move client to workspace N
  [((m .|. modMask, k), windows $ f i)

  --Keyboard layouts
  --qwerty users use this line
   | (i, k) <- zip (XMonad.workspaces conf) [xK_1,xK_2,xK_3,xK_4,xK_5,xK_6,xK_7,xK_8,xK_9,xK_0]


      , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)
      , (\i -> W.greedyView i . W.shift i, shiftMask)]]
  ++
  -- ctrl-{w,e,r}, Switch to physical/Xinerama screens 1, 2, or 3
  -- ctrl-shift-{w,e,r}, Move client to screen 1, 2, or 3
  [((m .|. controlMask, key), screenWorkspace sc >>= flip whenJust (windows . f))
      | (key, sc) <- zip [xK_w, xK_e] [0..]
      , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]

myMouseBindings (XConfig {XMonad.modMask = modMask}) = M.fromList $

    -- mod-button1, Set the window to floating mode and move by dragging
    [ ((modMask, 1), (\w -> focus w >> mouseMoveWindow w >> windows W.shiftMaster))

    -- mod-button2, Raise the window to the top of the stack
    , ((modMask, 2), (\w -> focus w >> windows W.shiftMaster))

    -- mod-button3, Set the window to floating mode and resize by dragging
    , ((modMask, 3), (\w -> focus w >> mouseResizeWindow w >> windows W.shiftMaster))

    ]

--XMOBAR
main = do

        xmproc0 <- spawnPipe "xmobar -x 0 $HOME/.config/xmobar/xmobarrc" -- xmobar monitor 1
        xmproc1 <- spawnPipe "xmobar -x 1 $HOME/.config/xmobar/xmobarrc" -- xmobar monitor 2
        xmonad $ ewmh $ mydefaults {
        logHook =  dynamicLogWithPP $ def {
        ppOutput = \x -> System.IO.hPutStrLn xmproc0 x  >> System.IO.hPutStrLn xmproc1 x
        , ppTitle = xmobarColor myTitleColor "" . shorten 60
        , ppCurrent = xmobarColor myCurrentWSColor "" . wrap """"
        , ppVisible = xmobarColor myVisibleWSColor "" . wrap """"
        , ppHidden = wrap """"
        , ppHiddenNoWindows = xmobarColor myHiddenNoWindowsWSColor ""
        , ppUrgent = xmobarColor myUrgentWSColor ""
        , ppSep = " : "
        , ppWsSep = "  "
        , ppOrder  = \(ws:l:t:ex) -> [ws]++ex++[t]

 }
}
