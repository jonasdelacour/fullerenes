c subroutine dddist takes 6 reals (=2 coordinates) and yields all 6 first derivatives,
c all 21 second derivatives of the distance and the the distance itself
      SUBROUTINE DDDIST(ax,ay,az,bx,by,bz,
     2 df__dax,df__day,df__daz,df__dbx,df__dby,df__dbz,
     3 ddf11dax__dax,ddf11dax__day,ddf11dax__daz,ddf11dax__dbx,
     4 ddf11dax__dby,ddf11dax__dbz,ddf11day__day,ddf11day__daz,
     5 ddf11day__dbx,ddf11day__dby,ddf11day__dbz,ddf11daz__daz,
     6 ddf11daz__dbx,ddf11daz__dby,ddf11daz__dbz,ddf11dbx__dbx,
     7 ddf11dbx__dby,ddf11dbx__dbz,ddf11dby__dby,ddf11dby__dbz,
     5 ddf11dbz__dbz,
     6 f)
      implicit real*8 (a-z)
      ab_x=ax-bx
      ab_y=ay-by
      ab_z=az-bz
      f=dsqrt((ab_x)**2 + (ab_y)**2 + (ab_z)**2)
      f_inv=1/f
      f_inv_cub=f_inv**3

c first derivatives
      dab_x__dax=1
      dab_x__dbx=-1
      dab_y__day=1
      dab_y__dby=-1
      dab_z__daz=1
      dab_z__dbz=-1

      df__dab_x=ab_x*f_inv
      df__dab_y=ab_y*f_inv
      df__dab_z=ab_z*f_inv

      df__dax=df__dab_x*dab_x__dax
      df__dbx=df__dab_x*dab_x__dbx
      df__day=df__dab_y*dab_y__day
      df__dby=df__dab_y*dab_y__dby
      df__daz=df__dab_z*dab_z__daz
      df__dbz=df__dab_z*dab_z__dbz

c second derivatives 

c f_inv=1/dsqrt((ab_x)**2 + (ab_y)**2 + (ab_z)**2)
      df_inv__dab_x=-ab_x*f_inv_cub
      df_inv__dab_y=-ab_y*f_inv_cub
      df_inv__dab_z=-ab_z*f_inv_cub

c f_inv=1/dsqrt((ab_x)**2 + (ab_y)**2 + (ab_z)**2)
      df_inv__dax=df_inv__dab_x*dab_x__dax
      df_inv__day=df_inv__dab_y*dab_y__day
      df_inv__daz=df_inv__dab_z*dab_z__daz
      df_inv__dbx=df_inv__dab_x*dab_x__dbx
      df_inv__dby=df_inv__dab_y*dab_y__dby
      df_inv__dbz=df_inv__dab_z*dab_z__dbz

      ddf11dab_x__f_inv=ab_x
      ddf11dab_y__f_inv=ab_y
      ddf11dab_z__f_inv=ab_z

      ddf11dab_x__dab_x=f_inv
      ddf11dab_y__dab_y=f_inv
      ddf11dab_z__dab_z=f_inv

c df__dab_x=ab_x*f_inv
c df__dab_y=ab_y*f_inv
c df__dab_z=ab_z*f_inv
      ddf11dab_x__dax=ddf11dab_x__dab_x*dab_x__dax
     2 + ddf11dab_x__f_inv*df_inv__dax
      ddf11dab_x__day=
     2 + ddf11dab_x__f_inv*df_inv__day
      ddf11dab_x__daz=
     2 + ddf11dab_x__f_inv*df_inv__daz
      ddf11dab_x__dbx=ddf11dab_x__dab_x*dab_x__dbx
     2 + ddf11dab_x__f_inv*df_inv__dbx
      ddf11dab_x__dby=
     2 + ddf11dab_x__f_inv*df_inv__dby
      ddf11dab_x__dbz=
     2 + ddf11dab_x__f_inv*df_inv__dbz
      ddf11dab_y__day=ddf11dab_y__dab_y*dab_y__day
     2 + ddf11dab_y__f_inv*df_inv__day
      ddf11dab_y__daz=
     2 + ddf11dab_y__f_inv*df_inv__daz
      ddf11dab_y__dbx=
     2 + ddf11dab_y__f_inv*df_inv__dbx
      ddf11dab_y__dby=ddf11dab_y__dab_y*dab_y__dby
     2 + ddf11dab_y__f_inv*df_inv__dby
      ddf11dab_y__dbz=
     2 + ddf11dab_y__f_inv*df_inv__dbz
      ddf11dab_z__daz=ddf11dab_z__dab_z*dab_z__daz
     2 + ddf11dab_z__f_inv*df_inv__daz
      ddf11dab_z__dbx=
     2 + ddf11dab_z__f_inv*df_inv__dbx
      ddf11dab_z__dby=
     2 + ddf11dab_z__f_inv*df_inv__dby
      ddf11dab_z__dbz=ddf11dab_z__dab_z*dab_z__dbz
     2 + ddf11dab_z__f_inv*df_inv__dbz

      ddf11dax__ddf11dab_x=dab_x__dax
      ddf11dax__ddab_x11dax=df__dab_x
      ddf11day__ddf11dab_y=dab_y__day
      ddf11day__ddab_y11day=df__dab_y
      ddf11daz__ddf11dab_z=dab_z__daz
      ddf11daz__ddab_z11daz=df__dab_z
      ddf11dbx__ddf11dab_x=dab_x__dbx
      ddf11dbx__ddab_x11dbx=df__dab_x
      ddf11dby__ddf11dab_y=dab_y__dby
      ddf11dby__ddab_y11dby=df__dab_y
      ddf11dbz__ddf11dab_z=dab_z__dbz
      ddf11dbz__ddab_z11dbz=df__dab_z

c df__dax=df__dab_x*dab_x__dax
      ddf11dax__dax=ddf11dax__ddf11dab_x*ddf11dab_x__dax
      ddf11dax__day=ddf11dax__ddf11dab_x*ddf11dab_x__day
      ddf11dax__daz=ddf11dax__ddf11dab_x*ddf11dab_x__daz
      ddf11dax__dbx=ddf11dax__ddf11dab_x*ddf11dab_x__dbx
      ddf11dax__dby=ddf11dax__ddf11dab_x*ddf11dab_x__dby
      ddf11dax__dbz=ddf11dax__ddf11dab_x*ddf11dab_x__dbz

c df__day=df__dab_y*dab_y__day
      ddf11day__day=ddf11day__ddf11dab_y*ddf11dab_y__day
      ddf11day__daz=ddf11day__ddf11dab_y*ddf11dab_y__daz
      ddf11day__dbx=ddf11day__ddf11dab_y*ddf11dab_y__dbx
      ddf11day__dby=ddf11day__ddf11dab_y*ddf11dab_y__dby
      ddf11day__dbz=ddf11day__ddf11dab_y*ddf11dab_y__dbz

c df__daz=df__dab_z*dab_z__daz
      ddf11daz__daz=ddf11daz__ddf11dab_z*ddf11dab_z__daz
      ddf11daz__dbx=ddf11daz__ddf11dab_z*ddf11dab_z__dbx
      ddf11daz__dby=ddf11daz__ddf11dab_z*ddf11dab_z__dby
      ddf11daz__dbz=ddf11daz__ddf11dab_z*ddf11dab_z__dbz

c df__dbx=df__dab_x*dab_x__dbx
      ddf11dbx__dbx=ddf11dbx__ddf11dab_x*ddf11dab_x__dbx
      ddf11dbx__dby=ddf11dbx__ddf11dab_x*ddf11dab_x__dby
      ddf11dbx__dbz=ddf11dbx__ddf11dab_x*ddf11dab_x__dbz

c df__dby=df__dab_y*dab_y__dby
      ddf11dby__dby=ddf11dby__ddf11dab_y*ddf11dab_y__dby
      ddf11dby__dbz=ddf11dby__ddf11dab_y*ddf11dab_y__dbz

c df__dbz=df__dab_z*dab_z__dbz
      ddf11dbz__dbz=ddf11dbz__ddf11dab_z*ddf11dab_z__dbz

      return
      END  




      SUBROUTINE DDDIHEDRAL(ax,ay,az,bx,by,bz,cx,cy,cz,dx,dy,dz,
     1 dax, day, daz, dbx, dby, dbz, dcx, dcy, dcz, ddx, ddy, ddz,
     1 daxdax, daxday, daxdaz, daxdbx, daxdby, daxdbz, daxdcx, daxdcy,
     1 daxdcz, daxddx, daxddy, daxddz, dayday, daydaz, daydbx, daydby,
     1 daydbz, daydcx, daydcy, daydcz, dayddx, dayddy, dayddz, dazdaz,
     1 dazdbx, dazdby, dazdbz, dazdcx, dazdcy, dazdcz, dazddx, dazddy,
     1 dazddz, dbxdbx, dbxdby, dbxdbz, dbxdcx, dbxdcy, dbxdcz, dbxddx,
     1 dbxddy, dbxddz, dbydby, dbydbz, dbydcx, dbydcy, dbydcz, dbyddx,
     1 dbyddy, dbyddz, dbzdbz, dbzdcx, dbzdcy, dbzdcz, dbzddx, dbzddy,
     1 dbzddz, dcxdcx, dcxdcy, dcxdcz, dcxddx, dcxddy, dcxddz, dcydcy,
     1 dcydcz, dcyddx, dcyddy, dcyddz, dczdcz, dczddx, dczddy, dczddz,
     1 ddxddx, ddxddy, ddxddz, ddyddy, ddyddz, ddzddz,
     1 dihedral_abcd)
      IMPLICIT REAL*8 (a-z)

C at first the dihedral (copied from above)
c vectors ab, bc and cd
      ab_x=ax-bx
      ab_y=ay-by
      ab_z=az-bz
      bc_x=bx-cx
      bc_y=by-cy
      bc_z=bz-cz
      cd_x=cx-dx
      cd_y=cy-dy
      cd_z=cz-dz
c vector bc normed to length 1
      bc_length_inv=1/dsqrt(bc_x**2 + bc_y**2 + bc_z**2)
      bc1_x=bc_x*bc_length_inv
      bc1_y=bc_y*bc_length_inv
      bc1_z=bc_z*bc_length_inv
c normal vectors on abc and bcd
c and the signs are this way because one of the two vectors points in the wrong direction
      abc_x=-ab_y*bc_z + ab_z*bc_y
      abc_y=-ab_z*bc_x + ab_x*bc_z
      abc_z=-ab_x*bc_y + ab_y*bc_x
      bcd_x=-bc_y*cd_z + bc_z*cd_y
      bcd_y=-bc_z*cd_x + bc_x*cd_z
      bcd_z=-bc_x*cd_y + bc_y*cd_x
c their respective lengths
      abc_length_inv=1/dsqrt(abc_x**2 + abc_y**2 + abc_z**2)
      bcd_length_inv=1/dsqrt(bcd_x**2 + bcd_y**2 + bcd_z**2)
c normal vectors (length 1) on abc and bcd
      abc1_x=abc_x*abc_length_inv
      abc1_y=abc_y*abc_length_inv
      abc1_z=abc_z*abc_length_inv
      bcd1_x=bcd_x*bcd_length_inv
      bcd1_y=bcd_y*bcd_length_inv
      bcd1_z=bcd_z*bcd_length_inv
c abc \times bcd
      aux_x=abc1_y*bc1_z-bc1_y*abc1_z
      aux_y=abc1_z*bc1_x-bc1_z*abc1_x
      aux_z=abc1_x*bc1_y-bc1_x*abc1_y
c two auxiliary reals
c     x=\vec abc1 \cdot \vec bcd_1
      x=abc1_x*bcd1_x + abc1_y*bcd1_y + abc1_z*bcd1_z
c     y=\vec aux  \cdot \vec bcd_1
      y=aux_x*bcd1_x + aux_y*bcd1_y + aux_z*bcd1_z
c the result
      dihedral_abcd=atan2(y, x)

C THE FISRT DERIVATIVES
c to be read from bottom to top

c bc_length_inv=1/dsqrt(bc_x**2 + bc_y**2 + bc_z**2)
      bc_length_inv_cub=bc_length_inv**3
      dbc_length_inv__dbc_x=-bc_x*bc_length_inv_cub
      dbc_length_inv__dbc_y=-bc_y*bc_length_inv_cub
      dbc_length_inv__dbc_z=-bc_z*bc_length_inv_cub

c bc1_x=bc_x*bc_length_inv
      dbc1_x__dbx=
     2 bc_length_inv + bc_x*dbc_length_inv__dbc_x
      dbc1_x__dby=
     2 bc_x*dbc_length_inv__dbc_y
      dbc1_x__dbz=
     2 bc_x*dbc_length_inv__dbc_z
      dbc1_x__dcx=
     2 -bc_length_inv - bc_x*dbc_length_inv__dbc_x
      dbc1_x__dcy=
     2 -bc_x*dbc_length_inv__dbc_y
      dbc1_x__dcz=
     2 -bc_x*dbc_length_inv__dbc_z
c bc1_y=bc_y*bc_length_inv
      dbc1_y__dbx=
     2 bc_y*dbc_length_inv__dbc_x
      dbc1_y__dby=
     2 bc_length_inv + bc_y*dbc_length_inv__dbc_y
      dbc1_y__dbz=
     2 bc_y*dbc_length_inv__dbc_z
      dbc1_y__dcx=
     2 -bc_y*dbc_length_inv__dbc_x
      dbc1_y__dcy=
     2 -bc_length_inv - bc_y*dbc_length_inv__dbc_y
      dbc1_y__dcz=
     2 -bc_y*dbc_length_inv__dbc_z
c bc1_z=bc_z*bc_length_inv
      dbc1_z__dbx=
     2 bc_z*dbc_length_inv__dbc_x
      dbc1_z__dby=
     2 bc_z*dbc_length_inv__dbc_y
      dbc1_z__dbz=
     2 bc_length_inv + bc_z*dbc_length_inv__dbc_z
      dbc1_z__dcx=
     2 -bc_z*dbc_length_inv__dbc_x
      dbc1_z__dcy=
     2 -bc_z*dbc_length_inv__dbc_y
      dbc1_z__dcz=
     2 -bc_length_inv - bc_z*dbc_length_inv__dbc_z

c abc_x=-ab_y*bc_z + ab_z*bc_y
      dabc_x__dby=bc_z + ab_z
      dabc_x__dbz=-ab_y - bc_y
c abc_y=-ab_z*bc_x + ab_x*bc_z
      dabc_y__dbx=-ab_z - bc_z
      dabc_y__dbz=bc_x + ab_x
c abc_z=-ab_x*bc_y + ab_y*bc_x
      dabc_z__dbx=ab_y + bc_y
      dabc_z__dby=-ab_x - bc_x 
c bcd_x=-bc_y*cd_z + bc_z*cd_y
      dbcd_x__dcy=cd_z + bc_z
      dbcd_x__dcz=-bc_y - cd_y 
c bcd_y=-bc_z*cd_x + bc_x*cd_z
      dbcd_y__dcx=-bc_z - cd_z 
      dbcd_y__dcz=cd_x + bc_x
c bcd_z=-bc_x*cd_y + bc_y*cd_x
      dbcd_z__dcx=cd_y + bc_y
      dbcd_z__dcy=-bc_x - cd_x

c abc_length_inv=1/dsqrt(abc_x**2 + abc_y**2 + abc_z**2)
      abc_length_inv_cub=abc_length_inv**3
      dabc_length_inv__dabc_x=-abc_x*abc_length_inv_cub
      dabc_length_inv__dabc_y=-abc_y*abc_length_inv_cub
      dabc_length_inv__dabc_z=-abc_z*abc_length_inv_cub

c bcd_length_inv=1/dsqrt(bcd_x**2 + bcd_y**2 + bcd_z**2)
      bcd_length_inv_cub=bcd_length_inv**3
      dbcd_length_inv__dbcd_x=-bcd_x*bcd_length_inv_cub
      dbcd_length_inv__dbcd_y=-bcd_y*bcd_length_inv_cub
      dbcd_length_inv__dbcd_z=-bcd_z*bcd_length_inv_cub

c abc_length_inv=1/dsqrt(abc_x**2 + abc_y**2 + abc_z**2)
      dabc_length_inv__dax=dabc_length_inv__dabc_y*bc_z
     4 - dabc_length_inv__dabc_z*bc_y
      dabc_length_inv__day=-dabc_length_inv__dabc_x*bc_z
     4 + dabc_length_inv__dabc_z*bc_x
      dabc_length_inv__daz=dabc_length_inv__dabc_x*bc_y
     3 - dabc_length_inv__dabc_y*bc_x
      dabc_length_inv__dbx=dabc_length_inv__dabc_y*dabc_y__dbx
     4 + dabc_length_inv__dabc_z*dabc_z__dbx
      dabc_length_inv__dby=dabc_length_inv__dabc_x*dabc_x__dby
     4 + dabc_length_inv__dabc_z*dabc_z__dby
      dabc_length_inv__dbz=dabc_length_inv__dabc_x*dabc_x__dbz
     3 + dabc_length_inv__dabc_y*dabc_y__dbz
      dabc_length_inv__dcx=dabc_length_inv__dabc_y*ab_z
     4 - dabc_length_inv__dabc_z*ab_y
      dabc_length_inv__dcy=-dabc_length_inv__dabc_x*ab_z
     4 + dabc_length_inv__dabc_z*ab_x
      dabc_length_inv__dcz=dabc_length_inv__dabc_x*ab_y
     3 - dabc_length_inv__dabc_y*ab_x

c bcd_length_inv=1/dsqrt(bcd_x**2 + bcd_y**2 + bcd_z**2)
c derivatives according to dax, day, daz
      dbcd_length_inv__dbx=dbcd_length_inv__dbcd_y*cd_z
     4 - dbcd_length_inv__dbcd_z*cd_y
      dbcd_length_inv__dby=-dbcd_length_inv__dbcd_x*cd_z
     4 + dbcd_length_inv__dbcd_z*cd_x
      dbcd_length_inv__dbz=dbcd_length_inv__dbcd_x*cd_y
     3 - dbcd_length_inv__dbcd_y*cd_x
      dbcd_length_inv__dcx=dbcd_length_inv__dbcd_y*dbcd_y__dcx
     4 + dbcd_length_inv__dbcd_z*dbcd_z__dcx
      dbcd_length_inv__dcy=dbcd_length_inv__dbcd_x*dbcd_x__dcy
     4 + dbcd_length_inv__dbcd_z*dbcd_z__dcy
      dbcd_length_inv__dcz=dbcd_length_inv__dbcd_x*dbcd_x__dcz
     3 + dbcd_length_inv__dbcd_y*dbcd_y__dcz
      dbcd_length_inv__ddx=dbcd_length_inv__dbcd_y*bc_z
     4 - dbcd_length_inv__dbcd_z*bc_y
      dbcd_length_inv__ddy=-dbcd_length_inv__dbcd_x*bc_z
     4 + dbcd_length_inv__dbcd_z*bc_x
      dbcd_length_inv__ddz=dbcd_length_inv__dbcd_x*bc_y
     3 - dbcd_length_inv__dbcd_y*bc_x


c derivation of the components of the normals
c abc1_x=abc_x*abc_length_inv
c abc1_y=abc_y*abc_length_inv
c abc1_z=abc_z*abc_length_inv
      dabc1_x__dax=
     2 abc_x*dabc_length_inv__dax
      dabc1_y__dax=abc_length_inv*bc_z +
     2 abc_y*dabc_length_inv__dax
      dabc1_z__dax=-abc_length_inv*bc_y +
     2 abc_z*dabc_length_inv__dax
      dabc1_x__day=- abc_length_inv*bc_z +
     2 abc_x*dabc_length_inv__day
      dabc1_y__day=
     2 abc_y*dabc_length_inv__day
      dabc1_z__day=abc_length_inv*bc_x +
     2 abc_z*dabc_length_inv__day
      dabc1_x__daz=abc_length_inv*bc_y +
     2 abc_x*dabc_length_inv__daz
      dabc1_y__daz=-abc_length_inv*bc_x +
     2 abc_y*dabc_length_inv__daz
      dabc1_z__daz=
     2 abc_z*dabc_length_inv__daz

      dabc1_x__dbx=
     2 abc_x*dabc_length_inv__dbx
      dabc1_y__dbx=abc_length_inv*dabc_y__dbx +
     2 abc_y*dabc_length_inv__dbx
      dabc1_z__dbx=abc_length_inv*dabc_z__dbx +
     2 abc_z*dabc_length_inv__dbx
      dabc1_x__dby=abc_length_inv*dabc_x__dby +
     2 abc_x*dabc_length_inv__dby
      dabc1_y__dby=
     2 abc_y*dabc_length_inv__dby
      dabc1_z__dby=abc_length_inv*dabc_z__dby +
     2 abc_z*dabc_length_inv__dby
      dabc1_x__dbz=abc_length_inv*dabc_x__dbz +
     2 abc_x*dabc_length_inv__dbz
      dabc1_y__dbz=abc_length_inv*dabc_y__dbz +
     2 abc_y*dabc_length_inv__dbz
      dabc1_z__dbz=
     2 abc_z*dabc_length_inv__dbz

      dabc1_x__dcx=
     2 abc_x*dabc_length_inv__dcx
      dabc1_y__dcx=abc_length_inv*ab_z +
     2 abc_y*dabc_length_inv__dcx
      dabc1_z__dcx=-abc_length_inv*ab_y +
     2 abc_z*dabc_length_inv__dcx
      dabc1_x__dcy=-abc_length_inv*ab_z +
     2 abc_x*dabc_length_inv__dcy
      dabc1_y__dcy=
     2 abc_y*dabc_length_inv__dcy
      dabc1_z__dcy=abc_length_inv*ab_x +
     2 abc_z*dabc_length_inv__dcy
      dabc1_x__dcz=abc_length_inv*ab_y +
     2 abc_x*dabc_length_inv__dcz
      dabc1_y__dcz=-abc_length_inv*ab_x +
     2 abc_y*dabc_length_inv__dcz
      dabc1_z__dcz=
     2 abc_z*dabc_length_inv__dcz


c bcd1_x=bcd_x*bcd_length_inv
c bcd1_y=bcd_y*bcd_length_inv
c bcd1_z=bcd_z*bcd_length_inv

      dbcd1_x__dbx=
     2 bcd_x*dbcd_length_inv__dbx
      dbcd1_y__dbx=bcd_length_inv*cd_z +
     2 bcd_y*dbcd_length_inv__dbx
      dbcd1_z__dbx=-bcd_length_inv*cd_y +
     2 bcd_z*dbcd_length_inv__dbx
      dbcd1_x__dby=-bcd_length_inv*cd_z +
     2 bcd_x*dbcd_length_inv__dby
      dbcd1_y__dby=
     2 bcd_y*dbcd_length_inv__dby
      dbcd1_z__dby=bcd_length_inv*cd_x +
     2 bcd_z*dbcd_length_inv__dby
      dbcd1_x__dbz=bcd_length_inv*cd_y +
     2 bcd_x*dbcd_length_inv__dbz
      dbcd1_y__dbz=-bcd_length_inv*cd_x +
     2 bcd_y*dbcd_length_inv__dbz
      dbcd1_z__dbz=
     2 bcd_z*dbcd_length_inv__dbz

      dbcd1_x__dcx=
     2 bcd_x*dbcd_length_inv__dcx
      dbcd1_y__dcx=bcd_length_inv*dbcd_y__dcx +
     2 bcd_y*dbcd_length_inv__dcx
      dbcd1_z__dcx=bcd_length_inv*dbcd_z__dcx +
     2 bcd_z*dbcd_length_inv__dcx
      dbcd1_x__dcy=bcd_length_inv*dbcd_x__dcy +
     2 bcd_x*dbcd_length_inv__dcy
      dbcd1_y__dcy=
     2 bcd_y*dbcd_length_inv__dcy
      dbcd1_z__dcy=bcd_length_inv*dbcd_z__dcy +
     2 bcd_z*dbcd_length_inv__dcy
      dbcd1_x__dcz=bcd_length_inv*dbcd_x__dcz +
     2 bcd_x*dbcd_length_inv__dcz
      dbcd1_y__dcz=bcd_length_inv*dbcd_y__dcz +
     2 bcd_y*dbcd_length_inv__dcz
      dbcd1_z__dcz=
     2 bcd_z*dbcd_length_inv__dcz

      dbcd1_x__ddx=
     2 bcd_x*dbcd_length_inv__ddx
      dbcd1_y__ddx=bcd_length_inv*bc_z +
     2 bcd_y*dbcd_length_inv__ddx
      dbcd1_z__ddx=-bcd_length_inv*bc_y +
     2 bcd_z*dbcd_length_inv__ddx
      dbcd1_x__ddy=-bcd_length_inv*bc_z +
     2 bcd_x*dbcd_length_inv__ddy
      dbcd1_y__ddy=
     2 bcd_y*dbcd_length_inv__ddy
      dbcd1_z__ddy=bcd_length_inv*bc_x +
     2 bcd_z*dbcd_length_inv__ddy
      dbcd1_x__ddz=bcd_length_inv*bc_y +
     2 bcd_x*dbcd_length_inv__ddz
      dbcd1_y__ddz=-bcd_length_inv*bc_x +
     2 bcd_y*dbcd_length_inv__ddz
      dbcd1_z__ddz=
     2 bcd_z*dbcd_length_inv__ddz

      daux_x__dax=
     2 bc1_z*dabc1_y__dax - bc1_y*dabc1_z__dax
      daux_x__day=
     2 bc1_z*dabc1_y__day - bc1_y*dabc1_z__day
      daux_x__daz=
     2 bc1_z*dabc1_y__daz - bc1_y*dabc1_z__daz
      daux_x__dbx=
     2 bc1_z*dabc1_y__dbx + abc1_y*dbc1_z__dbx
     4 - abc1_z*dbc1_y__dbx - bc1_y*dabc1_z__dbx
      daux_x__dby=
     2 bc1_z*dabc1_y__dby + abc1_y*dbc1_z__dby
     4 - abc1_z*dbc1_y__dby - bc1_y*dabc1_z__dby
      daux_x__dbz=
     2 bc1_z*dabc1_y__dbz + abc1_y*dbc1_z__dbz
     4 - abc1_z*dbc1_y__dbz - bc1_y*dabc1_z__dbz
      daux_x__dcx=
     2 bc1_z*dabc1_y__dcx + abc1_y*dbc1_z__dcx
     4 - abc1_z*dbc1_y__dcx - bc1_y*dabc1_z__dcx
      daux_x__dcy=
     2 bc1_z*dabc1_y__dcy + abc1_y*dbc1_z__dcy
     4 - abc1_z*dbc1_y__dcy - bc1_y*dabc1_z__dcy
      daux_x__dcz=
     2 bc1_z*dabc1_y__dcz + abc1_y*dbc1_z__dcz
     4 - abc1_z*dbc1_y__dcz - bc1_y*dabc1_z__dcz
c aux_y=abc1_z*bc1_x-bc1_z*abc1_x
      daux_y__dax=
     2 bc1_x*dabc1_z__dax - bc1_z*dabc1_x__dax
      daux_y__day=
     2 bc1_x*dabc1_z__day - bc1_z*dabc1_x__day
      daux_y__daz=
     2 bc1_x*dabc1_z__daz - bc1_z*dabc1_x__daz
      daux_y__dbx=
     2 bc1_x*dabc1_z__dbx + abc1_z*dbc1_x__dbx
     4 - abc1_x*dbc1_z__dbx - bc1_z*dabc1_x__dbx
      daux_y__dby=
     2 bc1_x*dabc1_z__dby + abc1_z*dbc1_x__dby
     4 - abc1_x*dbc1_z__dby - bc1_z*dabc1_x__dby
      daux_y__dbz=
     2 bc1_x*dabc1_z__dbz + abc1_z*dbc1_x__dbz
     4 - abc1_x*dbc1_z__dbz - bc1_z*dabc1_x__dbz
      daux_y__dcx=
     2 bc1_x*dabc1_z__dcx + abc1_z*dbc1_x__dcx
     4 - abc1_x*dbc1_z__dcx - bc1_z*dabc1_x__dcx
      daux_y__dcy=
     2 bc1_x*dabc1_z__dcy + abc1_z*dbc1_x__dcy
     4 - abc1_x*dbc1_z__dcy - bc1_z*dabc1_x__dcy
      daux_y__dcz=
     2 bc1_x*dabc1_z__dcz + abc1_z*dbc1_x__dcz
     4 - abc1_x*dbc1_z__dcz - bc1_z*dabc1_x__dcz
c      daux_y__ddx=0
c      daux_y__ddy=0
c      daux_y__ddz=0
c aux_z=abc1_x*bc1_y-bc1_x*abc1_y
      daux_z__dax=
     2 bc1_y*dabc1_x__dax - bc1_x*dabc1_y__dax
      daux_z__day=
     2 bc1_y*dabc1_x__day - bc1_x*dabc1_y__day
      daux_z__daz=
     2 bc1_y*dabc1_x__daz - bc1_x*dabc1_y__daz
      daux_z__dbx=
     2 bc1_y*dabc1_x__dbx + abc1_x*dbc1_y__dbx
     4 - abc1_y*dbc1_x__dbx - bc1_x*dabc1_y__dbx
      daux_z__dby=
     2 bc1_y*dabc1_x__dby + abc1_x*dbc1_y__dby
     4 - abc1_y*dbc1_x__dby - bc1_x*dabc1_y__dby
      daux_z__dbz=
     2 bc1_y*dabc1_x__dbz + abc1_x*dbc1_y__dbz
     4 - abc1_y*dbc1_x__dbz - bc1_x*dabc1_y__dbz
      daux_z__dcx=
     2 bc1_y*dabc1_x__dcx + abc1_x*dbc1_y__dcx
     4 - abc1_y*dbc1_x__dcx - bc1_x*dabc1_y__dcx
      daux_z__dcy=
     2 bc1_y*dabc1_x__dcy + abc1_x*dbc1_y__dcy
     4 - abc1_y*dbc1_x__dcy - bc1_x*dabc1_y__dcy
      daux_z__dcz=
     2 bc1_y*dabc1_x__dcz + abc1_x*dbc1_y__dcz
     4 - abc1_y*dbc1_x__dcz - bc1_x*dabc1_y__dcz
c      daux_z__ddx=0
c      daux_z__ddy=0
c      daux_z__ddz=0

c y=aux_x*bcd1_x + aux_y*bcd1_y + aux_z*bcd1_z
c x=abc1_x*bcd1_x + abc1_y*bcd1_y + abc1_z*bcd1_z
      dy__daux_x=bcd1_x
      dy__daux_y=bcd1_y
      dy__daux_z=bcd1_z

      dy__dbcd1_x=aux_x
      dy__dbcd1_y=aux_y
      dy__dbcd1_z=aux_z

      dx__dabc1_x=bcd1_x
      dx__dabc1_y=bcd1_y
      dx__dabc1_z=bcd1_z

      dx__dbcd1_x=abc1_x
      dx__dbcd1_y=abc1_y
      dx__dbcd1_z=abc1_z

c derivation of y
c y=aux_x*bcd1_x + aux_y*bcd1_y + aux_z*bcd1_z
      dy__dax=
     2 dy__daux_x*daux_x__dax + 
     3 dy__daux_y*daux_y__dax + 
     4 dy__daux_z*daux_z__dax  
      dy__day=
     2 dy__daux_x*daux_x__day + 
     3 dy__daux_y*daux_y__day + 
     4 dy__daux_z*daux_z__day 
      dy__daz=
     2 dy__daux_x*daux_x__daz + 
     3 dy__daux_y*daux_y__daz + 
     4 dy__daux_z*daux_z__daz 
      dy__dbx=
     2 dy__daux_x*daux_x__dbx + dy__dbcd1_x*dbcd1_x__dbx +
     3 dy__daux_y*daux_y__dbx + dy__dbcd1_y*dbcd1_y__dbx +
     4 dy__daux_z*daux_z__dbx + dy__dbcd1_z*dbcd1_z__dbx
      dy__dby=
     2 dy__daux_x*daux_x__dby + dy__dbcd1_x*dbcd1_x__dby +
     3 dy__daux_y*daux_y__dby + dy__dbcd1_y*dbcd1_y__dby +
     4 dy__daux_z*daux_z__dby + dy__dbcd1_z*dbcd1_z__dby
      dy__dbz=
     2 dy__daux_x*daux_x__dbz + dy__dbcd1_x*dbcd1_x__dbz +
     3 dy__daux_y*daux_y__dbz + dy__dbcd1_y*dbcd1_y__dbz +
     4 dy__daux_z*daux_z__dbz + dy__dbcd1_z*dbcd1_z__dbz
      dy__dcx=
     2 dy__daux_x*daux_x__dcx + dy__dbcd1_x*dbcd1_x__dcx +
     3 dy__daux_y*daux_y__dcx + dy__dbcd1_y*dbcd1_y__dcx +
     4 dy__daux_z*daux_z__dcx + dy__dbcd1_z*dbcd1_z__dcx
      dy__dcy=
     2 dy__daux_x*daux_x__dcy + dy__dbcd1_x*dbcd1_x__dcy +
     3 dy__daux_y*daux_y__dcy + dy__dbcd1_y*dbcd1_y__dcy +
     4 dy__daux_z*daux_z__dcy + dy__dbcd1_z*dbcd1_z__dcy
      dy__dcz=
     2 dy__daux_x*daux_x__dcz + dy__dbcd1_x*dbcd1_x__dcz +
     3 dy__daux_y*daux_y__dcz + dy__dbcd1_y*dbcd1_y__dcz +
     4 dy__daux_z*daux_z__dcz + dy__dbcd1_z*dbcd1_z__dcz
      dy__ddx=
     2 dy__dbcd1_x*dbcd1_x__ddx +
     3 dy__dbcd1_y*dbcd1_y__ddx +
     4 dy__dbcd1_z*dbcd1_z__ddx
      dy__ddy=
     2 dy__dbcd1_x*dbcd1_x__ddy +
     3 dy__dbcd1_y*dbcd1_y__ddy +
     4 dy__dbcd1_z*dbcd1_z__ddy
      dy__ddz=
     2 dy__dbcd1_x*dbcd1_x__ddz +
     3 dy__dbcd1_y*dbcd1_y__ddz +
     4 dy__dbcd1_z*dbcd1_z__ddz

c derivation of x
c x=abc1_x*bcd1_x + abc1_y*bcd1_y + abc1_z*bcd1_z
      dx__dax=
     2 dx__dabc1_x*dabc1_x__dax + 
     3 dx__dabc1_y*dabc1_y__dax + 
     4 dx__dabc1_z*dabc1_z__dax  
      dx__day=
     2 dx__dabc1_x*dabc1_x__day +
     3 dx__dabc1_y*dabc1_y__day + 
     4 dx__dabc1_z*dabc1_z__day 
      dx__daz=
     2 dx__dabc1_x*dabc1_x__daz + 
     3 dx__dabc1_y*dabc1_y__daz + 
     4 dx__dabc1_z*dabc1_z__daz 
      dx__dbx=
     2 dx__dabc1_x*dabc1_x__dbx + dx__dbcd1_x*dbcd1_x__dbx +
     3 dx__dabc1_y*dabc1_y__dbx + dx__dbcd1_y*dbcd1_y__dbx +
     4 dx__dabc1_z*dabc1_z__dbx + dx__dbcd1_z*dbcd1_z__dbx
      dx__dby=
     2 dx__dabc1_x*dabc1_x__dby + dx__dbcd1_x*dbcd1_x__dby +
     3 dx__dabc1_y*dabc1_y__dby + dx__dbcd1_y*dbcd1_y__dby +
     4 dx__dabc1_z*dabc1_z__dby + dx__dbcd1_z*dbcd1_z__dby
      dx__dbz=
     2 dx__dabc1_x*dabc1_x__dbz + dx__dbcd1_x*dbcd1_x__dbz +
     3 dx__dabc1_y*dabc1_y__dbz + dx__dbcd1_y*dbcd1_y__dbz +
     4 dx__dabc1_z*dabc1_z__dbz + dx__dbcd1_z*dbcd1_z__dbz
      dx__dcx=
     2 dx__dabc1_x*dabc1_x__dcx + dx__dbcd1_x*dbcd1_x__dcx +
     3 dx__dabc1_y*dabc1_y__dcx + dx__dbcd1_y*dbcd1_y__dcx +
     4 dx__dabc1_z*dabc1_z__dcx + dx__dbcd1_z*dbcd1_z__dcx
      dx__dcy=
     2 dx__dabc1_x*dabc1_x__dcy + dx__dbcd1_x*dbcd1_x__dcy +
     3 dx__dabc1_y*dabc1_y__dcy + dx__dbcd1_y*dbcd1_y__dcy +
     4 dx__dabc1_z*dabc1_z__dcy + dx__dbcd1_z*dbcd1_z__dcy
      dx__dcz=
     2 dx__dabc1_x*dabc1_x__dcz + dx__dbcd1_x*dbcd1_x__dcz +
     3 dx__dabc1_y*dabc1_y__dcz + dx__dbcd1_y*dbcd1_y__dcz +
     4 dx__dabc1_z*dabc1_z__dcz + dx__dbcd1_z*dbcd1_z__dcz
      dx__ddx=
     2 dx__dbcd1_x*dbcd1_x__ddx +
     3 dx__dbcd1_y*dbcd1_y__ddx +
     4 dx__dbcd1_z*dbcd1_z__ddx
      dx__ddy=
     2 dx__dbcd1_x*dbcd1_x__ddy +
     3 dx__dbcd1_y*dbcd1_y__ddy +
     4 dx__dbcd1_z*dbcd1_z__ddy
      dx__ddz=
     2 dx__dbcd1_x*dbcd1_x__ddz +
     3 dx__dbcd1_y*dbcd1_y__ddz +
     4 dx__dbcd1_z*dbcd1_z__ddz

c derivation atan2(y,x) according to x and y
      df__dx=-y/(x**2 + y**2)
      df__dy=x/(x**2 + y**2)

c derive f according to all 12 cartesion components of the four points
c f=atan2(y,x)
      df__dax=df__dx*dx__dax + df__dy*dy__dax
      df__day=df__dx*dx__day + df__dy*dy__day
      df__daz=df__dx*dx__daz + df__dy*dy__daz
      df__dbx=df__dx*dx__dbx + df__dy*dy__dbx
      df__dby=df__dx*dx__dby + df__dy*dy__dby
      df__dbz=df__dx*dx__dbz + df__dy*dy__dbz
      df__dcx=df__dx*dx__dcx + df__dy*dy__dcx
      df__dcy=df__dx*dx__dcy + df__dy*dy__dcy
      df__dcz=df__dx*dx__dcz + df__dy*dy__dcz
      df__ddx=df__dx*dx__ddx + df__dy*dy__ddx
      df__ddy=df__dx*dx__ddy + df__dy*dy__ddy
      df__ddz=df__dx*dx__ddz + df__dy*dy__ddz

c actually it would have to be df__dax etc
      dax=df__dax
      day=df__day
      daz=df__daz
      dbx=df__dbx
      dby=df__dby
      dbz=df__dbz
      dcx=df__dcx
      dcy=df__dcy
      dcz=df__dcz
      ddx=df__ddx
      ddy=df__ddy
      ddz=df__ddz

c f is the function atan2(y, x)
c fortran (and most other sources) use 'atan2(y,x)' while mathematica uses 'atan2(x,y)'

c////////////////////////////////////////////////////////////////////////
c////////////////////////////////////////////////////////////////////////
c// SECOND DERIVATIVES
c////////////////////////////////////////////////////////////////////////
c///////////////////////////////////////////////////////////////////////

      daxdax=ddf11dax__dax
      daxday=ddf11dax__day
      daxdaz=ddf11dax__daz
      daxdbx=ddf11dax__dbx
      daxdby=ddf11dax__dby
      daxdbz=ddf11dax__dbz
      daxdcx=ddf11dax__dcx
      daxdcy=ddf11dax__dcy
      daxdcz=ddf11dax__dcz
      daxddx=ddf11dax__ddx
      daxddy=ddf11dax__ddy
      daxddz=ddf11dax__ddz
      dayday=ddf11day__day
      daydaz=ddf11day__daz
      daydbx=ddf11day__dbx
      daydby=ddf11day__dby
      daydbz=ddf11day__dbz
      daydcx=ddf11day__dcx
      daydcy=ddf11day__dcy
      daydcz=ddf11day__dcz
      dayddx=ddf11day__ddx
      dayddy=ddf11day__ddy
      dayddz=ddf11day__ddz
      dazdaz=ddf11daz__daz
      dazdbx=ddf11daz__dbx
      dazdby=ddf11daz__dby
      dazdbz=ddf11daz__dbz
      dazdcx=ddf11daz__dcx
      dazdcy=ddf11daz__dcy
      dazdcz=ddf11daz__dcz
      dazddx=ddf11daz__ddx
      dazddy=ddf11daz__ddy
      dazddz=ddf11daz__ddz
      dbxdbx=ddf11dbx__dbx
      dbxdby=ddf11dbx__dby
      dbxdbz=ddf11dbx__dbz
      dbxdcx=ddf11dbx__dcx
      dbxdcy=ddf11dbx__dcy
      dbxdcz=ddf11dbx__dcz
      dbxddx=ddf11dbx__ddx
      dbxddy=ddf11dbx__ddy
      dbxddz=ddf11dbx__ddz
      dbydby=ddf11dby__dby
      dbydbz=ddf11dby__dbz
      dbydcx=ddf11dby__dcx
      dbydcy=ddf11dby__dcy
      dbydcz=ddf11dby__dcz
      dbyddx=ddf11dby__ddx
      dbyddy=ddf11dby__ddy
      dbyddz=ddf11dby__ddz
      dbzdbz=ddf11dbz__dbz
      dbzdcx=ddf11dbz__dcx
      dbzdcy=ddf11dbz__dcy
      dbzdcz=ddf11dbz__dcz
      dbzddx=ddf11dbz__ddx
      dbzddy=ddf11dbz__ddy
      dbzddz=ddf11dbz__ddz
      dcxdcx=ddf11dcx__dcx
      dcxdcy=ddf11dcx__dcy
      dcxdcz=ddf11dcx__dcz
      dcxddx=ddf11dcx__ddx
      dcxddy=ddf11dcx__ddy
      dcxddz=ddf11dcx__ddz
      dcydcy=ddf11dcy__dcy
      dcydcz=ddf11dcy__dcz
      dcyddx=ddf11dcy__ddx
      dcyddy=ddf11dcy__ddy
      dcyddz=ddf11dcy__ddz
      dczdcz=ddf11dcz__dcz
      dczddx=ddf11dcz__ddx
      dczddy=ddf11dcz__ddy
      dczddz=ddf11dcz__ddz
      ddxddx=ddf11ddx__ddx
      ddxddy=ddf11ddx__ddy
      ddxddz=ddf11ddx__ddz
      ddyddy=ddf11ddy__ddy
      ddyddz=ddf11ddy__ddz
      ddzddz=ddf11ddz__ddz

      return
      END SUBROUTINE
