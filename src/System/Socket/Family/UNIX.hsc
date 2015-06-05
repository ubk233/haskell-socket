{-# LANGUAGE TypeFamilies #-}
module System.Socket.Family.UNIX
  ( UNIX
  , SockAddrUn (..)
  ) where

import Data.Word
import qualified Data.ByteString as BS

import Foreign.Ptr
import Foreign.Storable
import Foreign.Marshal.Utils

import System.Socket.Family
import System.Socket.Internal.FFI

#include "hs_socket.h"
#let alignment t = "%lu", (unsigned long)offsetof(struct {char x__; t (y__); }, y__)

data UNIX

instance Family UNIX where
  type Address UNIX = SockAddrUn
  familyNumber _ = (#const AF_UNIX)

data SockAddrUn
   = SockAddrUn
     { sunPath :: BS.ByteString
     } deriving (Eq, Ord, Show)

instance Storable SockAddrUn where
  sizeOf    _ = (#size struct sockaddr_un)
  alignment _ = (#alignment struct sockaddr_un)
  peek ptr    = do
    path <- BS.packCString (sun_path ptr) :: IO BS.ByteString
    return (SockAddrUn path)
    where
      sun_path = (#ptr struct sockaddr_un, sun_path)
  poke ptr (SockAddrUn path) = do
    c_memset ptr 0 (#const sizeof(struct sockaddr_un))
    -- useAsCString null-terminates the CString
    BS.useAsCString truncatedPath $ \cs-> do
      copyBytes (sun_path ptr) cs (BS.length truncatedPath + 1)-- copyBytes dest from count
    where
      sun_path      = (#ptr struct sockaddr_un, sun_path)
      truncatedPath = BS.take ( sizeOf (undefined :: SockAddrUn)
                              - sizeOf (undefined :: Word16)
                              - 1 ) path